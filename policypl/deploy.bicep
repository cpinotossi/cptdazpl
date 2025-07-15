targetScope='subscription'

param location string
param prefix string
param username string
// param subscriptionId string

@secure()
param password string
param myobjectid string

@description('Choose between SystemAssigned or UserAssigned managed identity for policy assignments')
@allowed(['SystemAssigned', 'UserAssigned'])
param policyIdentityType string = 'UserAssigned'

// param ipsettingsHub object = {
//   vnet: '10.0.0.0/16'
//   prefix: '10.0.0.0/24'
//   vm: '10.0.0.4'
//   AzureBastionSubnet: '10.0.1.0/24'
// }

param ipsettingsSpoke1 object = {
  vnet: '10.1.0.0/16'
  prefix: '10.1.0.0/24'
  vm: '10.1.0.4'
  // AzureAPIMSubnet: '10.1.1.0/24'
  // AzureWebAppSubnet: '10.1.2.0/24'
}

//  -----------------------------------------------------
// Az 
//  -----------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: prefix
  location: location
}

// User-assigned managed identity for policy assignments (created conditionally)
module policyManagedIdentityModule 'bicep/modules/managedidentity.bicep' = {
  name: 'policyManagedIdentity'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    managedIdentityName: '${prefix}-policy-identity'
  }
}

//  -----------------------------------------------------
// Networking
//  -----------------------------------------------------

// module vnetHubModule 'bicep/modules/vnet.hub.bicep' = {
//   scope: resourceGroup(rg.name)
//   name: 'vnetHubDeploy'
//   params: {
//     prefix: '${prefix}hub'
//     location: location
//     ipsettings: ipsettingsHub
//     createBastion: true
//   }
//   dependsOn:[
//     rg
//   ]
// }

module vnetSpoke1Module 'bicep/modules/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnetSpoke1Deploy'
  params: {
    prefix: '${prefix}spoke1'
    location: location
    ipsettings: ipsettingsSpoke1
  }
  // dependsOn:[
  //   vnetHubModule
  // ]
}

// module peeringhub2spoke1 'bicep/modules/vpeer.bicep' = {
//   name: 'peeringhub2spoke1'
//   scope: resourceGroup(rg.name)
//   params: {
//     rgsourcename: rg.name
//     rgtargetname: rg.name
//     vnetsourcename: '${prefix}hub'
//     vnettargetname: '${prefix}spoke1'
//     useremotegateway: false
//   }
//   dependsOn:[
//     vnetHubModule
//     vnetSpoke1Module
//   ]
// }

// module peeringspoke12hub 'bicep/modules/vpeer.bicep' = {
//   name: 'peeringspoke12hub'
//   scope: resourceGroup(rg.name)
//   params: {
//     rgsourcename: rg.name
//     rgtargetname: rg.name
//     vnetsourcename: '${prefix}spoke1'
//     vnettargetname: '${prefix}hub'
//     useremotegateway: false
//   }
//   dependsOn:[
//     vnetHubModule
//     vnetSpoke1Module
//   ]
// }

module pdnsModule 'bicep/modules/pdns.bicep' = {
  name: 'pdns'
  scope: resourceGroup(rg.name)
  params: {
    privateDnsZoneName: 'privatelink.blob.core.windows.net'
    vnetIds: [
      vnetSpoke1Module.outputs.vnetId
      // vnetHubModule.outputs.vnetId
    ]
  }
  dependsOn:[
    // vnetHubModule
    vnetSpoke1Module
  ]
}


//  -----------------------------------------------------
// Compute
//  -----------------------------------------------------

// module vmHubModule 'bicep/modules/vm.bicep' = {
//   scope: resourceGroup(rg.name)
//   name: 'vmHubDeploy'
//   params: {
//     prefix: '${prefix}hub'
//     location: location
//     username: username
//     password: password
//     myobjectid: myobjectid
//     privateip: ipsettingsHub.vm
//   }
//   dependsOn:[
//     vnetHubModule
//   ]
// }

module vmSpoke1Module 'bicep/modules/vm.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vmSpoke1Deploy'
  params: {
    prefix: '${prefix}spoke1'
    location: location
    username: username
    password: password
    myobjectid: myobjectid
    privateip: ipsettingsSpoke1.vm
  }
  dependsOn:[
    vnetSpoke1Module
  ]
}

//  -----------------------------------------------------
// Storage
//  -----------------------------------------------------

// module sabModule 'bicep/modules/sab.bicep' = {
//   scope: resourceGroup(prefix)
//   name: 'sabDeploy'
//   params: {
//     prefix: '${prefix}2025'
//     objectIds: [
//       vmHubModule.outputs.vmManagedIdentityId
//       vmSpoke1Module.outputs.vmManagedIdentityId
//       myobjectid
//     ]
//     location: location
//     subnetId: vnetSpoke1Module.outputs.defaultSubnetId
//   }
// }

//  -----------------------------------------------------
// Monitoring
//  -----------------------------------------------------

module law 'bicep/modules/law.bicep' = {
  name: 'lawDeploy'
  scope: resourceGroup(prefix)
  params:{
    prefix: prefix
    location: location
  }
  dependsOn:[
    rg
  ]
}

//  -----------------------------------------------------
// Policy
//  -----------------------------------------------------

//  Read Parameter defintion which will be used with our Policies.
// var varPolicySetDefinitionEsDeployPrivateDNSZonesParameters = loadJsonContent('bicep/modules/policy/definitions/lib/policy_set_definitions/policy_set_definition_es_Deploy-Private-DNS-Zones.parameters.json')

// Read JSON Policy Defintion into Bicep variable
var varCustomPolicyDefinitionsArray = [
  {
		name: 'Deploy-Storage-PrivateEndpoint'
		libDefinition: loadJsonContent('bicep/modules/policy/definitions/lib/policy_definitions/policy_definition_Deploy-Private-DNS-Zone-Blob-Storage-Private-Endpoint.json')
	}
]

// Create list of Policy Set Definitions.
// Make use of our Parameter definttions.
// var varCustomPolicySetDefinitionsArray = [
// 	{
// 		name: 'Deploy-Private-DNS-Zones'
// 		libSetDefinition: loadJsonContent('bicep/modules/policy/definitions/lib/policy_set_definitions/policy_set_definition_es_Deploy-Private-DNS-Zones.json')
// 		libSetChildDefinitions: [
// 			{
// 				definitionReferenceId: 'DINE-Private-DNS-Azure-Storage-Blob'
//         // In our case we make use of the already build in Policy Definition "Configure a private DNS Zone ID for blob groupID" https://www.azadvertizer.net/azpolicyadvertizer/75973700-529f-4de2-b794-fb9b6781b6b0.html
// 				definitionId: '/providers/Microsoft.Authorization/policyDefinitions/75973700-529f-4de2-b794-fb9b6781b6b0'
// 				definitionParameters: varPolicySetDefinitionEsDeployPrivateDNSZonesParameters['DINE-Private-DNS-Azure-Storage-Blob'].parameters
// 				definitionGroups: []
// 				definitionVersion: '1.*.*'
// 			}
// 			{
// 				definitionReferenceId: 'DINE-Private-DNS-Azure-Storage-Blob-Sec'
//         // In our case we make use of the already build in Policy Definition "Configure a private DNS Zone ID for blob_secondary groupID" https://www.azadvertizer.net/azpolicyadvertizer/d847d34b-9337-4e2d-99a5-767e5ac9c582.html
// 				definitionId: '/providers/Microsoft.Authorization/policyDefinitions/d847d34b-9337-4e2d-99a5-767e5ac9c582'
// 				definitionParameters: varPolicySetDefinitionEsDeployPrivateDNSZonesParameters['DINE-Private-DNS-Azure-Storage-Blob-Sec'].parameters
// 				definitionGroups: []
// 				definitionVersion: '1.*.*'
// 			}
// 		]
// 	}
// ]

resource resPolicyDefinitions 'Microsoft.Authorization/policyDefinitions@2025-01-01' = [for policy in varCustomPolicyDefinitionsArray: {
  name: policy.libDefinition.name
  properties: {
    description: policy.libDefinition.properties.description
    displayName: policy.libDefinition.properties.displayName
    metadata: policy.libDefinition.properties.metadata
    mode: policy.libDefinition.properties.mode
    parameters: policy.libDefinition.properties.parameters
    policyType: policy.libDefinition.properties.policyType
    policyRule: policy.libDefinition.properties.policyRule
  }
}]

// resource resPolicySetDefinitions 'Microsoft.Authorization/policySetDefinitions@2025-01-01' = [for policySet in varCustomPolicySetDefinitionsArray: {
//   dependsOn: [
//     resPolicyDefinitions // Must wait for policy definitons to be deployed before starting the creation of Policy Set/Initiative Definitions
//   ]
//   name: policySet.libSetDefinition.name
//   properties: {
//     description: policySet.libSetDefinition.properties.description
//     displayName: policySet.libSetDefinition.properties.displayName
//     metadata: policySet.libSetDefinition.properties.metadata
//     parameters: policySet.libSetDefinition.properties.parameters
//     policyType: policySet.libSetDefinition.properties.policyType
//     policyDefinitions: [for policySetDef in policySet.libSetChildDefinitions: {
//       policyDefinitionReferenceId: policySetDef.definitionReferenceId
//       policyDefinitionId: policySetDef.definitionId
//       parameters: policySetDef.definitionParameters
//       groupNames: policySetDef.definitionGroups
// 			definitionVersion: !(empty(policySetDef.definitionVersion)) ? policySetDef.definitionVersion : null
//     }]
//     policyDefinitionGroups: policySet.libSetDefinition.properties.policyDefinitionGroups
//   }
// }]

// Configure a private DNS Zone ID for blob groupID - User Assigned Identity
module policyAssignmentUserModule 'bicep/modules/policyassignment.bicep' = {
  name: 'policyDeployStorageBlobPrivateEndpointAssignmentUser'
  scope: resourceGroup(prefix)
  params: {
    location: location
    policyAssignmentName: 'policyDeployStorageBlobPrivateEndpointAssignment'
    nonComplianceMessages: 'we will create the private endpoint dns entry for you PaaS'
    policyDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/policyDefinitions/Deploy-Storage-PrivateEndpoint'
    identityType: 'UserAssigned'
    userAssignedIdentityId: policyManagedIdentityModule!.outputs.managedIdentityId
    parameters: {
      privateDnsZoneId: {
        value: pdnsModule.outputs.privateDnsZoneId
      }
      privateEndpointGroupId: {
        value: 'blob'
      }
      effect: {
        value: 'DeployIfNotExists'
      }
    }
  }
  dependsOn:[
    resPolicyDefinitions
  ]
}
