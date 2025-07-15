targetScope='subscription'

param location string
param prefix string
param myobjectid string

//  -----------------------------------------------------
// Az 
//  -----------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: prefix
}

//  -----------------------------------------------------
// Networking
//  -----------------------------------------------------

resource vnetSpoke1 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: '${prefix}spoke1'
  scope: resourceGroup(rg.name)
}

//  -----------------------------------------------------
// Compute
//  -----------------------------------------------------

// Reference to an already existing VM in the hub vnet
resource vmSpoke1 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: '${prefix}spoke1'
  scope: resourceGroup(rg.name)
}

//  -----------------------------------------------------
// Monitoring
//  -----------------------------------------------------

resource law 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: prefix
  scope: resourceGroup(rg.name)
}

//  -----------------------------------------------------
// Storage
//  -----------------------------------------------------

module sabModule 'bicep/modules/sab.bicep' = {
  scope: resourceGroup(prefix)
  name: 'sabDeploy'
  params: {
    prefix: '${prefix}2025'
    objectIds: [
      vmSpoke1.identity.principalId
      myobjectid
    ]
    location: location
    subnetId: vnetSpoke1.properties.subnets[0].id
    workspaceId: law.id
  }
}
