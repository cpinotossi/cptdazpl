# Azure Private Endpoint and Azure Policy

Demo of how to create private endpoints DNS records using Azure Policy.

~~~powershell
az login --use-device-code
az account set --subscription "build"
$subid=az account show --query id -o tsv
$myobjectid=az ad signed-in-user show --query id --output tsv
$publicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content.Trim()
$location = (Get-Content ./parameters.json | ConvertFrom-Json).parameters.location.value
$prefix = (Get-Content ./parameters.json | ConvertFrom-Json).parameters.prefix.value
# az group delete -n $prefix --yes

# Deployment
$currentTimestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
az deployment sub create -n "deployment-$currentTimestamp" -l $location -f ./deploy.bicep -p '@parameters.json' -p myobjectid=$myobjectid

# Verify private dns zone entries
$privateDnsZoneName = "privatelink.blob.core.windows.net"
az network private-dns record-set a list --zone-name $privateDnsZoneName -g $prefix --query "[].{Name:name, IP:arecords[].ipv4Address}" -o table

# Deployment
$currentTimestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
az deployment sub create -n "deployment-$currentTimestamp" -l $location -f ./deploy.bicep -p '@parameters.json' -p myobjectid=$myobjectid

az network private-dns record-set a list --zone-name $privateDnsZoneName -g $prefix --query "[].{Name:name, IP:aRecords[0].ipv4Address}" -o table
Name          IP
------------  --------
cptdazplblob  10.1.0.5

# Get active logs related to policy activities under the resource group
$privateDnsId=az network private-dns zone show -g $prefix -n $privateDnsZoneName --query id -o tsv
az monitor activity-log list --resource-id $privateDnsId -g $prefix --start-time "2025-04-01T23:59:00" --offset 1h --query "[?contains(operationName.value, 'Microsoft.Authorization/policies/deployIfNotExists/action')].{eventTimestamp:eventTimestamp,authorization:authorization,category:category,operationName:operationName,properties:properties}"

[
  {
    "authorization": {
      "action": "Microsoft.Network/privateEndpoints/write",
      "scope": "/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourcegroups/cptdazpl/providers/Microsoft.Network/privateEndpoints/cptdazplblob"
    },
    "category": {
      "localizedValue": "Policy",
      "value": "Policy"
    },
    "eventTimestamp": "2025-04-01T22:02:23.0676295Z",
    "operationName": {
      "localizedValue": "'deployIfNotExists' Policy action.",
      "value": "Microsoft.Authorization/policies/deployIfNotExists/action"
    },
    "properties": {
      "ancestors": "ora2az.org,7a046593-b32d-45e8-a460-a81b3cf9e8e7",
      "createdResources": "[]",
      "deploymentId": "/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourceGroups/cptdazpl/providers/Microsoft.Resources/deployments/PolicyDeployment_10954783212093098182",   
      "deplymentProvisioningState": "Succeeded",
      "entity": "/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourcegroups/cptdazpl/providers/Microsoft.Network/privateEndpoints/cptdazplblob",
      "eventCategory": "Policy",
      "hierarchy": "",
      "isComplianceCheck": "False",
      "message": "Microsoft.Authorization/policies/deployIfNotExists/action",
      "policies": "[{\"policyDefinitionId\":\"/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/providers/Microsoft.Authorization/policyDefinitions/Deploy-Storage-PrivateEndpoint\",\"policyDefinitionName\":\"Deploy-Storage-PrivateEndpoint\",\"policyDefinitionDisplayName\":\"Deploys Private Endpoint for Blob Storage Account\",\"policyDefinitionVersion\":\"1.0.0\",\"policyDefinitionEffect\":\"DeployIfNotExists\",\"policyAssignmentId\":\"/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourcegroups/cptdazpl/providers/Microsoft.Authorization/policyAssignments/policyDeployPaaSPrivateEndpointAssignment\",\"policyAssignmentName\":\"policyDeployPaaSPrivateEndpointAssignment\",\"policyAssignmentDisplayName\":\"policyDeployPaaSPrivateEndpointAssignment\",\"policyAssignmentScope\":\"/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourcegroups/cptdazpl\",\"policyExemptionIds\":[],\"policyEnrollmentIds\":[]}]",
      "resourceLocation": "northeurope",
      "updatedResources": "[{\"id\":\"/subscriptions/e4ee7e61-47c9-4d0d-b625-4950e717f389/resourceGroups/cptdazpl/providers/Microsoft.Network/privateEndpoints/cptdazplblob/privateDnsZoneGroups/deployedByPolicy\"}]"
    }
  }
]
~~~
