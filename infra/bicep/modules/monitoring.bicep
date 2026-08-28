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

resource workspace 'Microsoft.Monitor/accounts@2025-10-03' = {
  name: 'ws-${resourceToken}'
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourceToken}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableLocalAuth: true
    WorkspaceResourceId: logAnalytics.id
    #disable-next-line BCP037
    AzureMonitorWorkspaceResourceId: workspace.id
    #disable-next-line BCP037
    AzureMonitorWorkspaceIngestionMode: 'Enabled'
  }
}

output applicationInsightsName string = applicationInsights.name
output applicationInsightsResourceId string = applicationInsights.id
output logAnalyticsWorkspaceResourceId string = logAnalytics.id
output azureMonitorWorkspaceResourceId string = workspace.id
#disable-next-line BCP053
output traceIngestionEndpoint string = applicationInsights.properties.OTLPTracesEndpoint
#disable-next-line BCP053
output logIngestionEndpoint string = applicationInsights.properties.OTLPLogsEndpoint
#disable-next-line BCP053
output metricsIngestionEndpoint string = applicationInsights.properties.OTLPMetricsEndpoint
#disable-next-line BCP053
output dataCollectionRuleResourceId string = applicationInsights.properties.DataCollectionRuleResourceId
