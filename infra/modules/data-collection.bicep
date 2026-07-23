@description('Name of the Data Collection Rule')
param dataCollectionRuleName string = 'otlp-dcr'

@description('Name of the Data Collection Endpoint')
param dataCollectionEndpointName string = 'otlp-dce'

@description('Location for the Data Collection resources')
param location string = resourceGroup().location

@description('Resource ID of the Application Insights instance')
param applicationInsightsResourceId string

@description('Resource ID of the Azure Monitor Workspace')
param azureMonitorWorkspaceResourceId string

@description('Resource ID of the Log Analytics Workspace')
param logAnalyticsWorkspaceResourceId string

@description('Object ID (principal ID) of the service principal to assign the Monitoring Metrics Publisher role on the Data Collection Rule. This is the Object ID of the enterprise application in Azure AD, not the Application/Client ID.')
param collectorServicePrincipalId string

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2024-03-11' = {
  name: dataCollectionEndpointName
  location: location
  properties: {
    description: 'Data Collection Endpoint for OTLP telemetry'
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    description: 'DCR to ingest OTLP telemetry via AMA (dataSources) or sent directly with OTel Collector (directDataSources)'
    dataCollectionEndpointId: dataCollectionEndpoint.id
    references: {
      applicationInsights: [
        {
          resourceId: applicationInsightsResourceId
          name: 'applicationInsightsResource'
        }
      ]
    }
    dataSources: {
      otelMetrics: [
        {
          streams: [
            'Custom-Metrics-Otel'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          name: 'otelMetricsDataSource'
        }
      ]
      otelLogs: [
        {
          streams: [
            'Microsoft-OTel-Logs'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          replaceResourceIdWithReference: true
          name: 'otelLogsDataSource'
        }
      ]
      otelTraces: [
        {
          streams: [
            'Microsoft-OTel-Traces-Spans'
            'Microsoft-OTel-Traces-Events'
            'Microsoft-OTel-Traces-Resources'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          replaceResourceIdWithReference: true
          name: 'otelTracesDataSource'
        }
      ]
    }
    directDataSources: {
      otelMetrics: [
        {
          streams: [
            'Custom-Metrics-Otel'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          name: 'otelMetricsDataSourceDirect'
        }
      ]
      otelLogs: [
        {
          streams: [
            'Microsoft-OTel-Logs'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          replaceResourceIdWithReference: true
          name: 'otelLogsDataSourceDirect'
        }
      ]
      otelTraces: [
        {
          streams: [
            'Microsoft-OTel-Traces-Spans'
            'Microsoft-OTel-Traces-Events'
            'Microsoft-OTel-Traces-Resources'
          ]
          enrichWithResourceAttributes: [
            '*'
          ]
          enrichWithReference: 'applicationInsightsResource'
          replaceResourceIdWithReference: true
          name: 'otelTracesDataSourceDirect'
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: azureMonitorWorkspaceResourceId
          name: 'myAMW'
        }
      ]
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspaceResourceId
          name: 'myLAW'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Custom-Metrics-Otel'
        ]
        destinations: [
          'myAMW'
        ]
      }
      {
        streams: [
          'Microsoft-OTel-Logs'
          'Microsoft-OTel-Traces-Spans'
          'Microsoft-OTel-Traces-Events'
          'Microsoft-OTel-Traces-Resources'
        ]
        destinations: [
          'myLAW'
        ]
      }
    ]
  }
}

// Grants the OTel Collector service principal permission to publish metrics and ingest telemetry
// via the Data Collection Rule.
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource collectorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(dataCollectionRule.id, collectorServicePrincipalId, monitoringMetricsPublisherRoleId)
  scope: dataCollectionRule
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
    principalId: collectorServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

output traceIngestionEndpoint string = '${dataCollectionEndpoint.properties.logsIngestion.endpoint}/dataCollectionRules/${dataCollectionRule.properties.immutableId}/streams/Microsoft-OTLP-Traces/otlp/v1/traces'
output logIngestionEndpoint string = '${dataCollectionEndpoint.properties.logsIngestion.endpoint}/dataCollectionRules/${dataCollectionRule.properties.immutableId}/streams/Microsoft-OTLP-Logs/otlp/v1/logs'
output metricsIngestionEndpoint string = '${dataCollectionEndpoint.properties.metricsIngestion.endpoint}/dataCollectionRules/${dataCollectionRule.properties.immutableId}/streams/Custom-Metrics-Otel/otlp/v1/metrics'
