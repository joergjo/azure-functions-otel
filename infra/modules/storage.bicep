/* Creates a storage account and uploads the deployed OpenTelemetry Collector
configuration to a publicly readable blob container. */

@description('Primary region for the storage resources.')
@minLength(1)
param location string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string

var collectorConfig = base64(loadTextContent('../../config/collector.deployed.yaml'))

resource storage 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: 'stconfig${resourceToken}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource configContainer 'containers' = {
      name: 'config'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

resource uploadCollectorConfig 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'upload-collector-config'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.74.0'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'STORAGE_ACCOUNT_NAME'
        value: storage.name
      }
      {
        name: 'STORAGE_ACCOUNT_KEY'
        secureValue: storage.listKeys().keys[0].value
      }
      {
        name: 'CONTAINER_NAME'
        value: storage::blobService::configContainer.name
      }
      {
        name: 'COLLECTOR_CONFIG'
        value: collectorConfig
      }
    ]
    scriptContent: '''
      config_file=/tmp/collector.deployed.yaml
      printf '%s' "$COLLECTOR_CONFIG" | base64 --decode > "$config_file"

      az storage blob upload \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$STORAGE_ACCOUNT_KEY" \
        --container-name "$CONTAINER_NAME" \
        --name collector.deployed.yaml \
        --file "$config_file" \
        --overwrite true \
        --only-show-errors
    '''
  }
}

output collectorConfigUrl string = '${storage.properties.primaryEndpoints.blob}config/collector.deployed.yaml'
