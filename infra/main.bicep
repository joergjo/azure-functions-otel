/* Orchestrates the deployment of a function app running in a Flex Consumption
plan that uses OpenTelemetry-based monitoring and consumes messages from an
Event Hub. The individual resources are defined in the modules under ./modules. */

//********************************************
// Parameters
//********************************************

@description('Primary region for all Azure resources.')
@minLength(1)
param location string = resourceGroup().location

@description('Language runtime used by the function app.')
@allowed(['dotnet-isolated', 'python', 'java', 'node', 'powerShell'])
param functionAppRuntime string = 'node'

@description('Target language version used by the function app.')
@allowed(['3.10', '3.11', '7.4', '8.0', '9.0', '10', '11', '17', '20', '22', '24'])
param functionAppRuntimeVersion string = '24'

@description('The maximum scale-out instance count limit for the app.')
@minValue(40)
@maxValue(1000)
param maximumInstanceCount int = 100

@description('The memory size of instances used by the app.')
@allowed([2048, 4096])
param instanceMemoryMB int = 2048

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, resourceGroup().id, location))

@description('A globally unique name for your deployed function app.')
param appName string = 'func-${resourceToken}'

@description('Specifies the name for the Event Hub Namespace.')
param namespaceName string = 'ehns-${resourceToken}'

@description('Specifies the name of a sample Event Hub to be created.')
param hubName string = 'test'

@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string = 'Standard'

@description('SKU for the Premium v4 App Service plan.')
param appServiceSku string = 'P0v4'

@description('Tier for the App Service plan.')
param appServiceTier string = 'PremiumV4'

@description('Client ID used by the OpenTelemetry Collector.')
param clientId string

@secure()
@description('Client secret used by the OpenTelemetry Collector.')
param clientSecret string

@description('Tenant ID used by the OpenTelemetry Collector.')
param tenantId string

//********************************************
// Modules
//********************************************

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    resourceToken: resourceToken
  }
}
module eventHubs 'modules/eventhubs.bicep' = {
  name: 'eventHubs'
  params: {
    location: location
    namespaceName: namespaceName
    hubName: hubName
    eventHubSku: eventHubSku
  }
}

module managedRedis 'modules/redis.bicep' = {
  name: 'managedRedis'
  params: {
    location: location
    resourceToken: resourceToken
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    resourceToken: resourceToken
  }
}

module appService 'modules/appservice.bicep' = {
  name: 'appService'
  params: {
    location: location
    resourceToken: resourceToken
    appServiceSku: appServiceSku
    appServiceTier: appServiceTier
    clientId: clientId
    clientSecret: clientSecret
    tenantId: tenantId
    logsEndpoint: monitoring.outputs.logIngestionEndpoint
    tracesEndpoint: monitoring.outputs.traceIngestionEndpoint
    metricsEndpoint: monitoring.outputs.metricsIngestionEndpoint
    collectorConfigUrl: storage.outputs.collectorConfigUrl
  }
}

module functions 'modules/functions.bicep' = {
  name: 'functions'
  params: {
    location: location
    resourceToken: resourceToken
    appName: appName
    functionAppRuntime: functionAppRuntime
    functionAppRuntimeVersion: functionAppRuntimeVersion
    maximumInstanceCount: maximumInstanceCount
    instanceMemoryMB: instanceMemoryMB
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    eventHubNamespaceName: eventHubs.outputs.namespaceName
    eventHubName: eventHubs.outputs.hubName
    otelCollectorHostName: appService.outputs.appServiceEndpoint
    managedRedisName: managedRedis.outputs.managedRedisName
  }
}

output functionsAppName string = functions.outputs.functionAppName
output functionAppEndpoint string = functions.outputs.functionAppEndpoint
output appServiceEndpoint string = appService.outputs.appServiceEndpoint
output eventHubNamespaceEndpoint string = eventHubs.outputs.serviceBusEndpoint
output managedRedisResourceId string = managedRedis.outputs.managedRedisResourceId
output traceIngestionEndpoint string = monitoring.outputs.traceIngestionEndpoint
output logIngestionEndpoint string = monitoring.outputs.logIngestionEndpoint
output metricsIngestionEndpoint string = monitoring.outputs.metricsIngestionEndpoint
output dcrResourceId string = monitoring.outputs.dataCollectionRuleResourceId
