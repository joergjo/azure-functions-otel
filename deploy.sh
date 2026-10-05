#!/bin/bash
set -e

if [ -z "$FUNCTIONS_RESOURCE_GROUP_NAME" ]; then
    echo "FUNCTIONS_RESOURCE_GROUP_NAME is not set. Please set it to the name of the resource group to deploy to."
    exit 1
fi

resource_group_name="$FUNCTIONS_RESOURCE_GROUP_NAME"
runtime=${FUNCTIONS_RUNTIME:-"node"}
version=${FUNCTIONS_RUNTIME_VERSION:-"24"}
location=${EVENTHUB_LOCATION:-swedencentral}
deployment_name="main-$(date +%s)"

sampler_parameters=()
if [ -n "${SAMPLER:-}" ]; then
  sampler_parameters+=("otelTracesSampler=$SAMPLER")
fi
if [ -n "${SAMPLER_ARG:-}" ]; then
  sampler_parameters+=("otelTracesSamplerArg=$SAMPLER_ARG")
fi

collector_parameters=()
if [ -n "${COLLECTOR_VERSION:-}" ]; then
  collector_parameters+=("collectorImageTag=$COLLECTOR_VERSION")
fi

az group create \
  --resource-group "$resource_group_name" \
  --location "$location" \
  --query id \
  --tags SecurityControl=Ignore \
  --output none

func_endpoint=$(az deployment group create \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --template-file ./infra/bicep/main.bicep\
  --parameters functionAppRuntime="$runtime" functionAppRuntimeVersion="$version" \
    "${collector_parameters[@]}" \
    "${sampler_parameters[@]}" \
  --query properties.outputs.functionAppEndpoint.value \
  --output tsv)

func_name=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.functionsAppName.value \
  --output tsv)

ehns_endpoint=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.eventHubNamespaceEndpoint.value \
  --output tsv)

log_ingestions_endpoint=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.logIngestionEndpoint.value \
  --output tsv)

trace_ingestion_endpoint=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.traceIngestionEndpoint.value \
  --output tsv)

metrics_ingestion_endpoint=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.metricsIngestionEndpoint.value \
  --output tsv)

dcr_resource_id=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.dcrResourceId.value \
  --output tsv)

collector_identity_principal_id=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.collectorIdentityPrincipalId.value \
  --output tsv)

collector_endpoint=$(az deployment group show \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --query properties.outputs.appServiceEndpoint.value \
  --output tsv)

echo "Creating role assignment for the OTel Collector managed identity on the Data Collection Rule (DCR)..."

az role assignment create \
  --assignee-object-id "$collector_identity_principal_id" \
  --assignee-principal-type ServicePrincipal \
  --role "3913510d-42f4-4e42-8a64-420c390055eb" \
  --scope "$dcr_resource_id" \
  --output none

echo "Azure resources have been deployed successfully to ${resource_group_name}." 
echo "Azure Function endpoint: https://${func_endpoint}"
echo "OpenTelemetry Collector endpoint: https://${collector_endpoint}"
echo "Event Hub Namespace endpoint: ${ehns_endpoint}"
echo
echo "Export the following environment variables to configure the OpenTelemetry Collector endpoints:"
echo "export LOGS_ENDPOINT='${log_ingestions_endpoint}'"
echo "export TRACES_ENDPOINT='${trace_ingestion_endpoint}'"
echo "export METRICS_ENDPOINT='${metrics_ingestion_endpoint}'"
echo
echo "Deploy the sample Functions app by running the following command:"
echo "func azure functionapp publish ${func_name}"
