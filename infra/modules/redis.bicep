/* Creates an Azure Managed Redis cluster and its required default database
using development-grade capacity and availability settings. */

@description('Primary region for the Azure Managed Redis resources.')
@minLength(1)
param location string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string

resource managedRedis 'Microsoft.Cache/redisEnterprise@2025-07-01' = {
  name: 'redis-${resourceToken}'
  location: location
  sku: {
    name: 'Balanced_B0'
  }
  properties: {
    encryption: {}
    highAvailability: 'Disabled'
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource defaultDatabase 'Microsoft.Cache/redisEnterprise/databases@2025-07-01' = {
  name: 'default'
  parent: managedRedis
  properties: {
    accessKeysAuthentication: 'Enabled'
    clientProtocol: 'Encrypted'
    clusteringPolicy: 'OSSCluster'
    evictionPolicy: 'VolatileLRU'
    modules: []
    persistence: {
      aofEnabled: false
      rdbEnabled: false
    }
    port: 10000
  }
}

output managedRedisName string = managedRedis.name
output managedRedisResourceId string = managedRedis.id
