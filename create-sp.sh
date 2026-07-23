#!/bin/bash
set -e

sp_name=${1:-"otel-collector"}

echo "Creating service principal '${sp_name}'..."

sp_json=$(az ad sp create-for-rbac --name "$sp_name")

client_id=$(echo "$sp_json" | jq --raw-output '.appId')
client_secret=$(echo "$sp_json" | jq --raw-output '.password')
tenant_id=$(az account show --query tenantId --output tsv)

echo "Service principal '${sp_name}' created successfully."
echo "Export the following environment variables:"
echo ""
echo "export CLIENT_ID='${client_id}'"
echo "export CLIENT_SECRET='${client_secret}'"
echo "export TENANT_ID='${tenant_id}'"
