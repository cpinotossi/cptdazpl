targetScope = 'resourceGroup'

@description('The location where the managed identity will be created')
param location string = resourceGroup().location

@description('The name of the managed identity')
param managedIdentityName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
