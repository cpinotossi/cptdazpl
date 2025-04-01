@description('The name of the Private DNS Zone.')
param privateDnsZoneName string

@description('The list of Virtual Network resource IDs to link.')
param vnetIds array

@description('The location for the resources.')
param location string = 'global'

var delimiter = '/'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
    name: privateDnsZoneName
    location: location
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnetId in vnetIds: {
    name: '${last(split(vnetId, delimiter))}-link'
    parent: privateDnsZone
    location: location
    properties: {
        virtualNetwork: {
            id: vnetId
        }
        registrationEnabled: false
    }
}]

output privateDnsZoneId string = privateDnsZone.id
