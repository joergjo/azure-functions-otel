#!/bin/bash
set -euo pipefail
umask 077

unset \
  TF_CLI_ARGS \
  TF_CLI_ARGS_apply \
  TF_CLI_ARGS_fmt \
  TF_CLI_ARGS_init \
  TF_CLI_ARGS_plan \
  TF_CLI_ARGS_show \
  TF_CLI_ARGS_state \
  TF_CLI_ARGS_validate

required_variables=(
  FUNCTIONS_RESOURCE_GROUP_NAME
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

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not available on PATH."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is not installed or not available on PATH."
  exit 1
fi

export TF_VAR_resource_group_name="$FUNCTIONS_RESOURCE_GROUP_NAME"
export TF_VAR_location="${EVENTHUB_LOCATION:-swedencentral}"
export TF_VAR_function_app_runtime="${FUNCTIONS_RUNTIME:-node}"
export TF_VAR_function_app_runtime_version="${FUNCTIONS_RUNTIME_VERSION:-24}"
export TF_VAR_client_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_client_secret="destroy-only-placeholder"
export TF_VAR_tenant_id="00000000-0000-0000-0000-000000000000"
export TF_VAR_collector_principal_id="00000000-0000-0000-0000-000000000000"

terraform_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/infra/terraform" && pwd)"
cd "$terraform_directory"

state_file="terraform.tfstate"

if [ ! -r "$state_file" ] || [ ! -s "$state_file" ]; then
  echo "Local Terraform state is absent or empty: ${terraform_directory}/terraform.tfstate"
  echo "Refusing to destroy resources without the existing deployment state."
  exit 1
fi

terraform init -input=false

if ! active_account=$(az account show --query '{subscriptionId:id,tenantId:tenantId}' --output json); then
  echo "Could not read the active Azure account. Run az login and select the deployment subscription."
  exit 1
fi

active_subscription_id=$(printf '%s' "$active_account" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("subscriptionId", ""))')
active_tenant_id=$(printf '%s' "$active_account" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("tenantId", ""))')

if [ -z "$active_subscription_id" ] || [ -z "$active_tenant_id" ]; then
  echo "Could not determine the active Azure subscription and tenant."
  exit 1
fi

effective_subscription_id="${ARM_SUBSCRIPTION_ID:-$active_subscription_id}"
effective_tenant_id="${ARM_TENANT_ID:-$active_tenant_id}"

if [ -n "${ARM_SUBSCRIPTION_ID:-}" ]; then
  normalized_provider_subscription_id=$(printf '%s' "$ARM_SUBSCRIPTION_ID" | tr '[:upper:]' '[:lower:]')
  normalized_active_subscription_id=$(printf '%s' "$active_subscription_id" | tr '[:upper:]' '[:lower:]')

  if [ "$normalized_provider_subscription_id" != "$normalized_active_subscription_id" ]; then
    echo "ARM_SUBSCRIPTION_ID selects subscription ${ARM_SUBSCRIPTION_ID}, but the active Azure CLI subscription is ${active_subscription_id}."
    echo "Select the same subscription in Azure CLI or unset ARM_SUBSCRIPTION_ID before retrying."
    exit 1
  fi
fi

if [ -n "${ARM_TENANT_ID:-}" ]; then
  normalized_provider_tenant_id=$(printf '%s' "$ARM_TENANT_ID" | tr '[:upper:]' '[:lower:]')
  normalized_active_tenant_id=$(printf '%s' "$active_tenant_id" | tr '[:upper:]' '[:lower:]')

  if [ "$normalized_provider_tenant_id" != "$normalized_active_tenant_id" ]; then
    echo "ARM_TENANT_ID selects tenant ${ARM_TENANT_ID}, but the active Azure CLI tenant is ${active_tenant_id}."
    echo "Select the same tenant in Azure CLI or unset ARM_TENANT_ID before retrying."
    exit 1
  fi
fi

if ! state_validation=$(
  terraform show -json "$state_file" |
    STATE_EXPECTED_RESOURCE_GROUP="$FUNCTIONS_RESOURCE_GROUP_NAME" \
    STATE_EFFECTIVE_SUBSCRIPTION="$effective_subscription_id" \
    STATE_EFFECTIVE_TENANT="$effective_tenant_id" \
    python3 -c '
import json
import os
import re
import sys

expected_group = os.environ["STATE_EXPECTED_RESOURCE_GROUP"]
effective_subscription = os.environ["STATE_EFFECTIVE_SUBSCRIPTION"]
effective_tenant = os.environ["STATE_EFFECTIVE_TENANT"]
allowed_modules = (
    "module.monitoring.",
    "module.eventhubs.",
    "module.redis.",
    "module.storage.",
    "module.appservice.",
    "module.functions.",
)
external_dcr_role = "module.monitoring.azapi_resource.monitoring_metrics_publisher"
azure_id_pattern = re.compile(
    r"^/subscriptions/([^/]+)/resourceGroups/([^/]+)(?:/|$)",
    re.IGNORECASE,
)
errors = []
evidence = []
managed_children = []

try:
    state = json.load(sys.stdin)
except (json.JSONDecodeError, UnicodeDecodeError) as error:
    print(f"Local Terraform state is not readable JSON: {error}", file=sys.stderr)
    sys.exit(1)

def visit(module):
    for resource in module.get("resources", []):
        address = resource.get("address", "")
        mode = resource.get("mode")
        values = resource.get("values") or {}

        if address != "azurerm_resource_group.this" and mode == "managed":
            managed_children.append(address)
            if not address.startswith(allowed_modules):
                errors.append(
                    f"Unexpected managed resource outside the six destroy targets: {address}"
                )

        resource_group_name = values.get("resource_group_name")
        if isinstance(resource_group_name, str) and resource_group_name:
            if resource_group_name.casefold() != expected_group.casefold():
                errors.append(
                    f"{address} has resource_group_name {resource_group_name!r}, "
                    f"not {expected_group!r}"
                )
            else:
                evidence.append(address)

        resource_id = values.get("id")
        if isinstance(resource_id, str):
            match = azure_id_pattern.match(resource_id)
            if match:
                subscription_id, resource_group_name = match.groups()
                if subscription_id.casefold() != effective_subscription.casefold():
                    errors.append(
                        f"{address} belongs to subscription {subscription_id}, "
                        f"not effective Terraform subscription {effective_subscription}"
                    )
                if resource_group_name.casefold() == expected_group.casefold():
                    evidence.append(address)
                elif address == external_dcr_role:
                    normalized_id = resource_id.casefold()
                    if (
                        "/providers/microsoft.insights/datacollectionrules/" not in normalized_id
                        or "/providers/microsoft.authorization/roleassignments/" not in normalized_id
                    ):
                        errors.append(
                            f"{address} is not a role assignment on an Azure Monitor DCR: "
                            f"{resource_id}"
                        )
                else:
                    errors.append(
                        f"{address} belongs to resource group {resource_group_name!r}, "
                        f"not {expected_group!r}"
                    )

        subscription_id = values.get("subscription_id")
        if (
            isinstance(subscription_id, str)
            and subscription_id
            and subscription_id.casefold() != effective_subscription.casefold()
        ):
            errors.append(
                f"{address} records subscription {subscription_id}, "
                f"not effective Terraform subscription {effective_subscription}"
            )

        tenant_id = values.get("tenant_id")
        if (
            isinstance(tenant_id, str)
            and tenant_id
            and tenant_id.casefold() != effective_tenant.casefold()
        ):
            errors.append(
                f"{address} records tenant {tenant_id}, "
                f"not effective Terraform tenant {effective_tenant}"
            )

    for child_module in module.get("child_modules", []):
        visit(child_module)

root_module = state.get("values", {}).get("root_module")
if not isinstance(root_module, dict):
    print("Local Terraform state has no readable root module.", file=sys.stderr)
    sys.exit(1)

visit(root_module)

if managed_children and not evidence:
    errors.append(
        "Managed child resources remain, but state contains no resource group name or "
        "Azure resource ID that identifies the requested resource group."
    )

if errors:
    print("Local Terraform state validation failed:", file=sys.stderr)
    for error in errors:
        print(f"  - {error}", file=sys.stderr)
    sys.exit(1)

print(len(managed_children))
'
); then
  echo "Refusing to plan a destroy from mismatched or ambiguous local Terraform state."
  echo "Align the Terraform provider and Azure CLI contexts, and restore FUNCTIONS_RESOURCE_GROUP_NAME before retrying."
  exit 1
fi

managed_child_count="$state_validation"

if [ "$managed_child_count" -eq 0 ]; then
  echo "Local Terraform state contains no managed child resources. Nothing to destroy."
  echo "The resource group ${FUNCTIONS_RESOURCE_GROUP_NAME} remains preserved."
  exit 0
fi

terraform fmt -check -recursive
terraform validate

plan_file=".terraform/destroy.tfplan"
trap 'rm -f "$plan_file"' EXIT

echo "The resource group ${FUNCTIONS_RESOURCE_GROUP_NAME} will be preserved."
echo "Only state-managed child resources will be included in the destroy plan."
terraform plan -destroy \
  -target=module.monitoring \
  -target=module.eventhubs \
  -target=module.redis \
  -target=module.storage \
  -target=module.appservice \
  -target=module.functions \
  -out="$plan_file" \
  -lock-timeout=5m

if terraform show -json "$plan_file" |
  python3 -c '
import json
import sys

plan = json.load(sys.stdin)
allowed_prefixes = (
    "module.monitoring.",
    "module.eventhubs.",
    "module.redis.",
    "module.storage.",
    "module.appservice.",
    "module.functions.",
)
changes = [
    (
        change.get("address", ""),
        tuple(change.get("change", {}).get("actions", [])),
    )
    for change in plan.get("resource_changes", [])
]

if any(
    "create" in action or "update" in action or "replace" in action
    for _, action in changes
):
    sys.exit(2)

outside_deletes = [
    address
    for address, action in changes
    if "delete" in action and not address.startswith(allowed_prefixes)
]
if outside_deletes:
    print(
        "Destroy plan contains delete actions outside the six allowed modules:",
        file=sys.stderr,
    )
    for address in outside_deletes:
        print(f"  - {address}", file=sys.stderr)
    sys.exit(4)

if not any("delete" in action for _, action in changes):
    sys.exit(3)
'; then
  :
else
  inspection_status=$?

  if [ "$inspection_status" -eq 3 ]; then
    echo "Managed child resources remain in state, but the destroy plan contains no delete actions."
    echo "Refusing to apply an ambiguous no-op plan."
    exit 1
  elif [ "$inspection_status" -eq 4 ]; then
    echo "The saved destroy plan would delete azurerm_resource_group.this or another resource outside the six allowed modules."
    echo "Refusing to apply the plan."
    exit 1
  else
    echo "The saved destroy plan contains an unexpected create, update, or replace action, or could not be inspected safely."
    echo "Refusing to apply the plan."
    exit 1
  fi
fi

echo "Review the destroy plan above carefully."
if ! read -r -p "Type the exact resource group name (${FUNCTIONS_RESOURCE_GROUP_NAME}) to continue: " confirmation; then
  echo
  echo "Confirmation was not received. Destruction cancelled."
  exit 1
fi

if [ "$confirmation" != "$FUNCTIONS_RESOURCE_GROUP_NAME" ]; then
  echo "Confirmation did not exactly match ${FUNCTIONS_RESOURCE_GROUP_NAME}. Destruction cancelled."
  exit 1
fi

terraform apply -lock-timeout=5m "$plan_file"

if terraform state list | grep -Fxq 'azurerm_resource_group.this'; then
  terraform state rm azurerm_resource_group.this
fi
