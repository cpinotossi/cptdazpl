targetScope='resourceGroup'

param prefix string
param location string
param ipsettings object
param createBastion bool


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
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints:[
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ipsettings.AzureBastionSubnet
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      ]
      virtualNetworkPeerings: []
      enableDdosProtection: false
      }
    }


resource pubipbastion 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (createBastion){
  name: '${prefix}bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = if (createBastion) {
  name: prefix
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsName: '${prefix}.bastion.azure.com'
    enableTunneling: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

@description('VNet Name')
output vnetName string = vnet.name
output vnetId string = vnet.id
output defaultSubnetId string = '${vnet.id}/subnets/${prefix}'
output vnetCidr string = vnet.properties.addressSpace.addressPrefixes[0]

