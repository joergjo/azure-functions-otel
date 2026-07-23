#!/bin/bash
set -e

if [ -z "$FUNCTIONS_RESOURCE_GROUP_NAME" ]; then
    echo "FUNCTIONS_RESOURCE_GROUP_NAME is not set. Please set it to the name of the resource group to deploy to."
    exit 1
fi

if [ -z "$CLIENT_ID" ]; then
    echo "CLIENT_ID is not set. Please set it to the Application (Client) ID of the OTel Collector service principal."
    exit 1
fi

resource_group_name="$FUNCTIONS_RESOURCE_GROUP_NAME"
runtime=${FUNCTIONS_RUNTIME:-"node"}
version=${FUNCTIONS_RUNTIME_VERSION:-"24"}
location=${EVENTHUB_LOCATION:-swedencentral}
deployment_name="main-$(date +%s)"

collector_sp_id=$(az ad sp show --id "$CLIENT_ID" --query id --output tsv)

az group create \
  --resource-group "$resource_group_name" \
  --location "$location" \
  --query id \
  --tags SecurityControl=Ignore \
  --output none

func_endpoint=$(az deployment group create \
  --resource-group "$resource_group_name" \
  --name "$deployment_name" \
  --template-file ./infra/main.bicep\
  --parameters functionAppRuntime="$runtime" functionAppRuntimeVersion="$version" collectorServicePrincipalId="$collector_sp_id" \
  --query properties.outputs.functionAppEndpoint.value \
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

echo "Azure resources have been deployed successfully to ${resource_group_name}." 
echo "Azure Function endpoint: ${func_endpoint}"
echo "Event Hub Namespace endpoint: ${ehns_endpoint}"
echo "export LOGS_ENDPOINT='${log_ingestions_endpoint}'"
echo "export TRACES_ENDPOINT='${trace_ingestion_endpoint}'"
echo "export METRICS_ENDPOINT='${metrics_ingestion_endpoint}'"
