#!/bin/bash
set -euo pipefail
umask 077

required_variables=(
  FUNCTIONS_RESOURCE_GROUP_NAME
  CLIENT_ID
  CLIENT_SECRET
  TENANT_ID
)

for variable_name in "${required_variables[@]}"; do
  if [ -z "${!variable_name:-}" ]; then
    echo "${variable_name} is not set."
    exit 1
  fi
done

if ! command -v az >/dev/null 2>&1; then
  echo "az is not installed or not available on PATH."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not installed or not available on PATH."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is not installed or not available on PATH."
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not available on PATH."
  exit 1
fi

export TF_VAR_resource_group_name="$FUNCTIONS_RESOURCE_GROUP_NAME"
export TF_VAR_location="${EVENTHUB_LOCATION:-swedencentral}"
export TF_VAR_function_app_runtime="${FUNCTIONS_RUNTIME:-node}"
export TF_VAR_function_app_runtime_version="${FUNCTIONS_RUNTIME_VERSION:-24}"
export TF_VAR_client_id="$CLIENT_ID"
export TF_VAR_client_secret="$CLIENT_SECRET"
export TF_VAR_tenant_id="$TENANT_ID"
export TF_VAR_collector_principal_id
TF_VAR_collector_principal_id=$(az ad sp show --id "$CLIENT_ID" --query id --output tsv)

if [ -n "${COLLECTOR_VERSION:-}" ]; then
  export TF_VAR_collector_image_tag="$COLLECTOR_VERSION"
fi

if [ -n "${SAMPLER:-}" ]; then
  export TF_VAR_otel_traces_sampler="$SAMPLER"
fi

if [ -n "${SAMPLER_ARG:-}" ]; then
  export TF_VAR_otel_traces_sampler_arg="$SAMPLER_ARG"
fi

terraform_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/infra/terraform" && pwd)"
cd "$terraform_directory"

terraform init

arm_response_file=".terraform/arm-response.$$"
arm_request_file=".terraform/arm-request.$$"
plan_file=".terraform/deploy.tfplan"

cleanup() {
  rm -f "$arm_response_file" "$arm_request_file" "$plan_file"
}
trap cleanup EXIT

active_subscription_id=$(az account show --query id --output tsv)

if [ -z "$active_subscription_id" ]; then
  echo "Could not determine the active Azure subscription."
  exit 1
fi

expected_resource_group_id="/subscriptions/${active_subscription_id}/resourceGroups/${FUNCTIONS_RESOURCE_GROUP_NAME}"
normalized_expected_resource_group_id=$(printf '%s' "$expected_resource_group_id" | tr '[:upper:]' '[:lower:]')
state_resource_group_id=""

if [ -s terraform.tfstate ]; then
  if ! state_addresses=$(terraform state list); then
    echo "The local Terraform state is corrupt or unreadable."
    exit 1
  fi

  if printf '%s\n' "$state_addresses" | grep -Fxq 'azurerm_resource_group.this'; then
    if ! state_resource_group=$(terraform state show -no-color azurerm_resource_group.this); then
      echo "Could not read azurerm_resource_group.this from local Terraform state."
      exit 1
    fi

    state_resource_group_id=$(
      printf '%s\n' "$state_resource_group" |
        sed -n 's/^[[:space:]]*id[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p'
    )

    if [ -z "$state_resource_group_id" ]; then
      echo "The local Terraform state entry azurerm_resource_group.this has no readable ID."
      exit 1
    fi
  fi
fi

if [ -n "$state_resource_group_id" ]; then
  normalized_state_resource_group_id=$(printf '%s' "$state_resource_group_id" | tr '[:upper:]' '[:lower:]')

  if [ "$normalized_state_resource_group_id" != "$normalized_expected_resource_group_id" ]; then
    echo "The local Terraform state manages a different resource group: ${state_resource_group_id}"
    echo "Select the matching Azure subscription or restore FUNCTIONS_RESOURCE_GROUP_NAME before retrying."
    exit 1
  fi
fi

arm_access_token=$(az account get-access-token \
  --resource https://management.azure.com/ \
  --query accessToken \
  --output tsv)

if [ -z "$arm_access_token" ]; then
  echo "Could not acquire an ARM access token."
  exit 1
fi

encoded_resource_group_name=$(
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' \
    "$FUNCTIONS_RESOURCE_GROUP_NAME"
)
resource_group_url="https://management.azure.com/subscriptions/${active_subscription_id}/resourcegroups/${encoded_resource_group_name}?api-version=2022-09-01"

arm_status=$(
  curl --silent --show-error \
    --output "$arm_response_file" \
    --write-out '%{http_code}' \
    --header "Authorization: Bearer ${arm_access_token}" \
    "$resource_group_url"
)

case "$arm_status" in
200)
  resource_group_details=$(
    python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as response:
    resource_group = json.load(response)
print(resource_group.get("id", ""))
print(resource_group.get("location", ""))
' "$arm_response_file"
  )
  resource_group_id=$(printf '%s\n' "$resource_group_details" | sed -n '1p')
  existing_location=$(printf '%s\n' "$resource_group_details" | sed -n '2p')

  if [ -z "$resource_group_id" ] || [ -z "$existing_location" ]; then
    echo "ARM returned an incomplete resource group response."
    exit 1
  fi

  normalized_resource_group_id=$(printf '%s' "$resource_group_id" | tr '[:upper:]' '[:lower:]')
  if [ "$normalized_resource_group_id" != "$normalized_expected_resource_group_id" ]; then
    echo "ARM returned an unexpected resource group ID: ${resource_group_id}"
    exit 1
  fi

  normalized_existing_location=$(printf '%s' "$existing_location" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
  normalized_requested_location=$(printf '%s' "$TF_VAR_location" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

  if [ "$normalized_existing_location" != "$normalized_requested_location" ]; then
    echo "Resource group ${FUNCTIONS_RESOURCE_GROUP_NAME} already exists in ${existing_location}, not ${TF_VAR_location}."
    echo "Set EVENTHUB_LOCATION to the existing location to avoid replacing the resource group."
    exit 1
  fi
  ;;
404)
  python3 -c '
import json
import sys

with open(sys.argv[1], "w", encoding="utf-8") as request:
    json.dump({"location": sys.argv[2], "tags": {"SecurityControl": "Ignore"}}, request)
' "$arm_request_file" "$TF_VAR_location"

  arm_status=$(
    curl --silent --show-error \
      --request PUT \
      --output "$arm_response_file" \
      --write-out '%{http_code}' \
      --header "Authorization: Bearer ${arm_access_token}" \
      --header "Content-Type: application/json" \
      --data-binary "@${arm_request_file}" \
      "$resource_group_url"
  )

  case "$arm_status" in
  200 | 201) ;;
  *)
    echo "ARM resource group creation failed with HTTP status ${arm_status}."
    exit 1
    ;;
  esac

  created_resource_group_details=$(
    python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as response:
    resource_group = json.load(response)
print(resource_group.get("id", ""))
print(resource_group.get("location", ""))
' "$arm_response_file"
  )
  created_resource_group_id=$(printf '%s\n' "$created_resource_group_details" | sed -n '1p')
  created_location=$(printf '%s\n' "$created_resource_group_details" | sed -n '2p')
  resource_group_id="$created_resource_group_id"

  if [ -z "$resource_group_id" ] || [ -z "$created_location" ]; then
    echo "ARM returned an incomplete resource group creation response."
    exit 1
  fi

  normalized_resource_group_id=$(printf '%s' "$resource_group_id" | tr '[:upper:]' '[:lower:]')
  if [ "$normalized_resource_group_id" != "$normalized_expected_resource_group_id" ]; then
    echo "ARM returned an unexpected resource group ID after creation: ${resource_group_id}"
    exit 1
  fi

  normalized_created_location=$(printf '%s' "$created_location" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
  normalized_requested_location=$(printf '%s' "$TF_VAR_location" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

  if [ "$normalized_created_location" != "$normalized_requested_location" ]; then
    echo "ARM returned resource group ${FUNCTIONS_RESOURCE_GROUP_NAME} in ${created_location}, not ${TF_VAR_location}."
    exit 1
  fi
  ;;
*)
  echo "ARM resource group lookup failed with HTTP status ${arm_status}."
  exit 1
  ;;
esac
unset arm_access_token

if [ -n "$resource_group_id" ] && [ -z "$state_resource_group_id" ]; then
  terraform import azurerm_resource_group.this "$resource_group_id"
fi

terraform fmt -check -recursive
terraform validate

terraform plan -out="$plan_file"
terraform apply "$plan_file"

function_app_name=$(terraform output -raw function_app_name)
function_app_endpoint=$(terraform output -raw function_app_endpoint)
collector_endpoint=$(terraform output -raw app_service_endpoint)
event_hub_namespace_endpoint=$(terraform output -raw event_hub_namespace_endpoint)
logs_endpoint=$(terraform output -raw log_ingestion_endpoint)
traces_endpoint=$(terraform output -raw trace_ingestion_endpoint)
metrics_endpoint=$(terraform output -raw metrics_ingestion_endpoint)

echo "Azure resources have been deployed successfully to ${FUNCTIONS_RESOURCE_GROUP_NAME}."
echo "Azure Function endpoint: ${function_app_endpoint}"
echo "OpenTelemetry Collector endpoint: ${collector_endpoint}"
echo "Event Hub Namespace endpoint: ${event_hub_namespace_endpoint}"
echo "export LOGS_ENDPOINT='${logs_endpoint}'"
echo "export TRACES_ENDPOINT='${traces_endpoint}'"
echo "export METRICS_ENDPOINT='${metrics_endpoint}'"
echo "You can now deploy the application by running:"
echo "func azure functionapp publish ${function_app_name}"
