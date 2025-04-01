targetScope = 'subscription'

metadata description = 'This policy definition is used to deploy custom policy definitions'

// This variable contains a number of objects that load in the custom Azure Policy Defintions that are provided as part of the ESLZ/ALZ reference implementation - this is automatically created in the file 'infra-as-code\bicep\modules\policy\lib\policy_definitions\_policyDefinitionsBicepInput.txt' via a GitHub action, that runs on a daily schedule, and is then manually copied into this variable.
var varCustomPolicyDefinitionsArray = [
	{
		name: 'Deny-Private-DNS-Zones'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Private-DNS-Zones.json')
	}
	{
		name: 'Deny-Storage-ContainerDeleteRetentionPolicy'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-ContainerDeleteRetentionPolicy.json')
	}
	{
		name: 'Deny-Storage-CopyScope'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-CopyScope.json')
	}
	{
		name: 'Deny-Storage-CorsRules'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-CorsRules.json')
	}
	{
		name: 'Deny-Storage-LocalUser'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-LocalUser.json')
	}
	{
		name: 'Deny-Storage-minTLS'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-minTLS.json')
	}
	{
		name: 'Deny-Storage-NetworkAclsBypass'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-NetworkAclsBypass.json')
	}
	{
		name: 'Deny-Storage-NetworkAclsVirtualNetworkRules'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-NetworkAclsVirtualNetworkRules.json')
	}
	{
		name: 'Deny-Storage-ResourceAccessRulesResourceId'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-ResourceAccessRulesResourceId.json')
	}
	{
		name: 'Deny-Storage-ResourceAccessRulesTenantId'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-ResourceAccessRulesTenantId.json')
	}
	{
		name: 'Deny-Storage-ServicesEncryption'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-ServicesEncryption.json')
	}
	{
		name: 'Deny-Storage-SFTP'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-Storage-SFTP.json')
	}
	{
		name: 'Deny-StorageAccount-CustomDomain'
		libDefinition: loadJsonContent('lib/policy_definitions/policy_definition_es_Deny-StorageAccount-CustomDomain.json')
	}
]

// This variable contains a number of objects that load in the custom Azure Policy Set/Initiative Defintions that are provided as part of the ESLZ/ALZ reference implementation - this is automatically created in the file 'infra-as-code\bicep\modules\policy\lib\policy_set_definitions\_policySetDefinitionsBicepInput.txt' via a GitHub action, that runs on a daily schedule, and is then manually copied into this variable.
var varCustomPolicySetDefinitionsArray = [
	{
		name: 'Deploy-Private-DNS-Zones'
		libSetDefinition: loadJsonContent('lib/policy_set_definitions/policy_set_definition_es_Deploy-Private-DNS-Zones.json')
		libSetChildDefinitions: [
			{
				definitionReferenceId: 'DINE-Private-DNS-Azure-Storage-Blob'
				definitionId: '/providers/Microsoft.Authorization/policyDefinitions/75973700-529f-4de2-b794-fb9b6781b6b0'
				definitionParameters: varPolicySetDefinitionEsDeployPrivateDNSZonesParameters['DINE-Private-DNS-Azure-Storage-Blob'].parameters
				definitionGroups: []
				definitionVersion: '1.*.*'
			}
			{
				definitionReferenceId: 'DINE-Private-DNS-Azure-Storage-Blob-Sec'
				definitionId: '/providers/Microsoft.Authorization/policyDefinitions/d847d34b-9337-4e2d-99a5-767e5ac9c582'
				definitionParameters: varPolicySetDefinitionEsDeployPrivateDNSZonesParameters['DINE-Private-DNS-Azure-Storage-Blob-Sec'].parameters
				definitionGroups: []
				definitionVersion: '1.*.*'
			}
		]
	}
]

// Policy Set/Initiative Definition Parameter Variables

var varPolicySetDefinitionEsDeployPrivateDNSZonesParameters = loadJsonContent('lib/policy_set_definitions/policy_set_definition_es_Deploy-Private-DNS-Zones.parameters.json')


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

resource resPolicySetDefinitions 'Microsoft.Authorization/policySetDefinitions@2025-01-01' = [for policySet in varCustomPolicySetDefinitionsArray: {
  dependsOn: [
    resPolicyDefinitions // Must wait for policy definitons to be deployed before starting the creation of Policy Set/Initiative Defininitions
  ]
  name: policySet.libSetDefinition.name
  properties: {
    description: policySet.libSetDefinition.properties.description
    displayName: policySet.libSetDefinition.properties.displayName
    metadata: policySet.libSetDefinition.properties.metadata
    parameters: policySet.libSetDefinition.properties.parameters
    policyType: policySet.libSetDefinition.properties.policyType
    policyDefinitions: [for policySetDef in policySet.libSetChildDefinitions: {
      policyDefinitionReferenceId: policySetDef.definitionReferenceId
      policyDefinitionId: policySetDef.definitionId
      parameters: policySetDef.definitionParameters
      groupNames: policySetDef.definitionGroups
			definitionVersion: !(empty(policySetDef.definitionVersion)) ? policySetDef.definitionVersion : null
    }]
    policyDefinitionGroups: policySet.libSetDefinition.properties.policyDefinitionGroups
  }
}]

