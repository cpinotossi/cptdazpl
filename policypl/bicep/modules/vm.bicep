targetScope='resourceGroup'

param prefix string
param location string
@secure()
param password string
param username string
param myobjectid string
param privateip string


resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: prefix
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: prefix
  location: location
  properties: {
    ipConfigurations: [
      {
        name: prefix
        properties: {
          privateIPAddress:privateip
          // privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${vnet.id}/subnets/${prefix}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

// resource sshkey 'Microsoft.Compute/sshPublicKeys@2024-07-01' = {
//   name: prefix
//   location: location
//   properties: {
//     publicKey: loadTextContent('../ssh/chpinoto.pub')
//   }
// }

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: prefix
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      osDisk: {
        name: prefix
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption:'Delete'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: prefix
      adminUsername: username
      adminPassword: password
      // customData: loadFileAsBase64('vm.yaml')
      linuxConfiguration:{
        // ssh:{
        //   publicKeys: [
        //     {
        //       path:'/home/chpinoto/.ssh/authorized_keys'
        //       keyData: sshkey.properties.publicKey
        //     }
        //   ]
        // }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties:{
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vmaadextension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'AADSSHLoginForLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
  }
}

resource nwagentextension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'NetworkWatcherAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentLinux'
    typeHandlerVersion: '1.4'
  }
}

var roleVirtualMachineAdministratorName = '1c0163c0-47e6-4577-8991-ea5c82e286e4' //Virtual Machine Administrator Login

resource raMe2VM 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id,'raMe2VMHub')
  properties: {
    principalId: myobjectid
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions',roleVirtualMachineAdministratorName)
  }
}

output vmName string = vm.name
output vmId string = vm.id
output vmManagedIdentityId string = vm.identity.principalId
