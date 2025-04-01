param vnetsourcename string
param vnettargetname string
param useremotegateway bool = false
param rgsourcename string
param rgtargetname string
param allowForwardedTraffic bool = true
param allowVirtualNetworkAccess bool = true
param allowGatewayTransit bool = true

resource vnetsource 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetsourcename
  scope: resourceGroup(rgsourcename)
}

resource vnettarget 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnettargetname
  scope: resourceGroup(rgtargetname)
}

resource peeringsource2target 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${vnetsource.name}/${vnetsource.name}${vnettarget.name}'
  properties: {
    remoteVirtualNetwork: {
      id: vnettarget.id
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useremotegateway
  }
}
