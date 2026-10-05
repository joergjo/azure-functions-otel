/* Creates a Linux App Service plan and web app running the OpenTelemetry
Collector Contrib image from Docker Hub. */

@description('Primary region for the App Service resources.')
@minLength(1)
param location string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string

@description('SKU for the Premium v4 App Service plan.')
param appServiceSku string

@description('Tier for the App Service plan.')
param appServiceTier string

@description('Tag and optional digest for the OpenTelemetry Collector Contrib container image.')
@minLength(1)
param collectorImageTag string

@description('Azure Monitor logs ingestion endpoint.')
param logsEndpoint string

@description('Azure Monitor traces ingestion endpoint.')
param tracesEndpoint string

@description('Azure Monitor metrics ingestion endpoint.')
param metricsEndpoint string

@description('Absolute URL of the OpenTelemetry Collector configuration.')
param collectorConfigUrl string

@description('Content hash of the OpenTelemetry Collector configuration, used only to force an App Service restart when the config content changes.')
param collectorConfigHash string

var collectorAppSettings = [
  {
    name: 'WEBSITES_PORT'
    value: '4318'
  }
  {
    name: 'HTTP20_ONLY_PORT'
    value: '4317'
  }
  {
    name: 'CLIENT_ID'
    value: userAssignedIdentity.properties.clientId
  }
  {
    name: 'LOGS_ENDPOINT'
    value: logsEndpoint
  }
  {
    name: 'TRACES_ENDPOINT'
    value: tracesEndpoint
  }
  {
    name: 'METRICS_ENDPOINT'
    value: metricsEndpoint
  }
  {
    // Not read by the collector; App Service restarts whenever app settings
    // change, which guarantees a restart (and config reload) exactly when
    // the config content actually changes, since appCommandLine's blob URL
    // never changes between deployments.
    name: 'COLLECTOR_CONFIG_HASH'
    value: collectorConfigHash
  }
]

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'uai-collector-${resourceToken}'
  location: location
}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: 'asp-${resourceToken}'
  location: location
  kind: 'linux'
  sku: {
    name: appServiceSku
    tier: appServiceTier
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2025-03-01' = {
  name: 'app-${resourceToken}'
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientCertEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|otel/opentelemetry-collector-contrib:${collectorImageTag}'
      appCommandLine: '--config=${collectorConfigUrl}'
      http20Enabled: true
      http20ProxyFlag: 2
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      requestTracingEnabled: true
      appSettings: collectorAppSettings
      alwaysOn: true
    }
  }
}

output appServiceEndpoint string = appService.properties.defaultHostName
output collectorIdentityPrincipalId string = userAssignedIdentity.properties.principalId
