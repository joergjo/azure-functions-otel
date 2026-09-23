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

@description('Client ID used by the OpenTelemetry Collector.')
param clientId string

@secure()
@description('Client secret used by the OpenTelemetry Collector.')
param clientSecret string

@description('Tenant ID used by the OpenTelemetry Collector.')
param tenantId string

@description('Azure Monitor logs ingestion endpoint.')
param logsEndpoint string

@description('Azure Monitor traces ingestion endpoint.')
param tracesEndpoint string

@description('Azure Monitor metrics ingestion endpoint.')
param metricsEndpoint string

@description('Absolute URL of the OpenTelemetry Collector configuration.')
param collectorConfigUrl string

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
    value: clientId
  }
  {
    name: 'CLIENT_SECRET'
    value: clientSecret
  }
  {
    name: 'TENANT_ID'
    value: tenantId
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
]

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
    type: 'SystemAssigned'
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
