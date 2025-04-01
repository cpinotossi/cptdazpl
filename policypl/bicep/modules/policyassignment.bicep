targetScope='resourceGroup'

@description('The name of the policy assignment')
param policyAssignmentName string

@description('The policy definition reference ID to assign')
param policyDefinitionId string

@description('Parameters for the policy assignment')
param parameters object = {}

param nonComplianceMessages string 
param location string 

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: policyAssignmentName
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  properties: {
    policyDefinitionId: policyDefinitionId
    parameters: parameters
    displayName: policyAssignmentName
    nonComplianceMessages: [{
      message: nonComplianceMessages
    }]
  }
}

@description('The contributor role definition ID to assign to the managed identity')
param roleDefinitionId string = '4d97b98b-1d4f-4787-a291-c67834d212e7'

param privateDNSContributorRoleDefinitionId string = 'befefa01-2a29-4197-83a8-272ff33ce314'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(policyAssignmentName, roleDefinitionId, resourceGroup().id)
  properties: {
    principalId: policyAssignment.identity.principalId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
  dependsOn: [
    policyAssignment
  ]
}

output policyAssignmentId string = policyAssignment.id
output policyAssignmentNameOutput string = policyAssignment.name
