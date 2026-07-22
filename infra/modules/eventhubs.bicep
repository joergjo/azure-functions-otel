/* Creates the Event Hub namespace and a sample Event Hub that the
function app consumes messages from. */

@description('Primary region for the Event Hub resources.')
@minLength(1)
param location string

@description('Name for the Event Hub Namespace.')
param namespaceName string

@description('Name of the sample Event Hub to be created.')
param hubName string

@description('Messaging tier for the Event Hub Namespace.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string = 'Standard'

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: namespaceName
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    disableLocalAuth: false
    isAutoInflateEnabled: false
    zoneRedundant: true
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: hubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 4
  }
}

output namespaceName string = eventHubNamespace.name
output hubName string = eventHub.name
output serviceBusEndpoint string = eventHubNamespace.properties.serviceBusEndpoint
