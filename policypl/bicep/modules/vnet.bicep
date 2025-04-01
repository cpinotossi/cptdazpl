// Private Endpoint integration
targetScope = 'resourceGroup'

param prefix string
param location string
param ipsettings object
param privateEndpointNetworkPolicies string = 'Disabled'
param privateLinkServiceNetworkPolicies string = 'Disabled'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: prefix
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ipsettings.vnet
      ]
    }
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: ipsettings.prefix
          delegations: []
          privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
          privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
          // serviceEndpoints: [
          //   {
          //     service: 'Microsoft.Storage'
          //     locations: [
          //       location
          //     ]
          //   }
          // ]
          // networkSecurityGroup: useNSG ? {
          //   id: nsgDefault.id
          // }: null
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

// resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2024-05-01' = if (useNSG) {
//   name: '${prefix}default'
//   location: location
//   properties: {
//     securityRules: []
//   }
// }

@description('VNet Name')
output vnetName string = vnet.name
output vnetId string = vnet.id
output defaultSubnetId string = '${vnet.id}/subnets/${prefix}'
output vnetCidr string = vnet.properties.addressSpace.addressPrefixes[0]
