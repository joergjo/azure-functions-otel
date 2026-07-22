/* Creates the Log Analytics workspace and Application Insights component
used for OpenTelemetry-based monitoring of the function app. */

@description('Primary region for the monitoring resources.')
@minLength(1)
param location string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: 'log-${resourceToken}'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourceToken}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    DisableLocalAuth: true
  }
}

resource workspaces 'Microsoft.Monitor/accounts@2025-10-03' = {
  name: 'ws-${resourceToken}'
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

output applicationInsightsName string = applicationInsights.name
output applicationInsightsResourceId string = applicationInsights.id
output logAnalyticsWorkspaceResourceId string = logAnalytics.id
output azureMonitorWorkspaceResourceId string = workspaces.id
