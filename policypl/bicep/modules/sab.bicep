targetScope='resourceGroup'

param prefix string
param location string
param subnetId string
param objectIds array

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: prefix
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    accessTier: 'Hot'
  }
}

resource sab 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

resource sac 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: sab
  name: prefix
  properties: {
    // publicAccess: 'Blob'
  }
}

var roleStorageBlobDataContributorName = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor

resource rablobcontributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for objectId in objectIds: {
  name: guid(resourceGroup().id, 'rablobcontributort', objectId)
  properties: {
    principalId: objectId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/RoleDefinitions', roleStorageBlobDataContributorName)
  }
}]

resource pe 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: prefix
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: prefix
        properties: {
          privateLinkServiceId: sa.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    customNetworkInterfaceName: prefix
  }
}
