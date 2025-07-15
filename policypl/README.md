# Azure Private Endpoint and Azure Policy

Demo of how to create private endpoints DNS records for Blob Storage Account using Azure Policy.

~~~powershell
az login --use-device-code
$subid=(Get-Content ./parameters.json | ConvertFrom-Json).parameters.subscriptionId.value
az account set --subscription $subid
$myobjectid=az ad signed-in-user show --query id --output tsv
$publicip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content.Trim()
$location = (Get-Content ./parameters.json | ConvertFrom-Json).parameters.location.value
$prefix = (Get-Content ./parameters.json | ConvertFrom-Json).parameters.prefix.value
# az group delete -n $prefix --yes
~~~

## Deployment

~~~powershell
$currentTimestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
az deployment sub create -n "deployment-$currentTimestamp" -l $location -f ./deploy.bicep -p '@parameters.json' -p myobjectid=$myobjectid
~~~

## Verify if Policy "Deploy-Storage-Blob-PrivateEndpoint" has been created

~~~powershell
az policy definition list --query "[?contains(name, 'Deploy-Storage-PrivateEndpoint')]" > output.Deploy-Storage-PrivateEndpoint.json
az policy definition list --query "[?contains(name, 'Deploy-Storage-PrivateEndpoint')].{Name:name, id:id}"
~~~

~~~json
[
  {
    "Name": "Deploy-Storage-PrivateEndpoint",
    "id": "/subscriptions/11c61beb-b32b-4166-9d6c-74cb3a2e04da/providers/Microsoft.Authorization/policyDefinitions/Deploy-Storage-PrivateEndpoint"
  }
]
~~~

Location of the policy definition is at Subscription Scope.

## Verify if policy assignment has been created

~~~powershell
az policy assignment list -g $prefix --query "[?contains(name, 'policyDeployStorageBlobPrivateEndpointAssignment')]" > output.policyDeployPaaSPrivateEndpointAssignment.json
az policy assignment list -g $prefix --query "[?contains(name, 'policyDeployStorageBlobPrivateEndpointAssignment')].{Name:name, id:id}"
~~~

~~~json
[
  {
    "Name": "policyDeployStorageBlobPrivateEndpointAssignment",
    "id": "/subscriptions/11c61beb-b32b-4166-9d6c-74cb3a2e04da/resourcegroups/cptdazpl/providers/Microsoft.Authorization/policyAssignments/policyDeployStorageBlobPrivateEndpointAssignment"
  }
]
~~~

Policy assignment is created at Resource Group Scope.

## Verify if private dns zone has been created

~~~powershell
az network private-dns zone list -g $prefix --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
~~~

Name                               ResourceGroup
---------------------------------  ---------------
privatelink.blob.core.windows.net  cptdazpl

## Verify private dns zone entries exit

Currently we do not expect any entries in the private DNS zone, as the policy has not been applied yet.

~~~powershell
$privateDnsZoneName = "privatelink.blob.core.windows.net"
az network private-dns record-set a list --zone-name $privateDnsZoneName -g $prefix --query "[].{Name:name, IP:arecords[].ipv4Address}" -o table
~~~

Empty output, as expected.


## Deployment of Storage Acccount with Private Endpoint

~~~powershell
$currentTimestamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
az deployment sub create -n "deployment-$currentTimestamp" -l $location -f ./deploy.storage.bicep -p '@parameters.storage.json' -p myobjectid=$myobjectid
~~~

## Verify if Storage Account is created

~~~powershell
az storage account list -g $prefix --query "[].{Name:name, Location:location, SKU:sku.name}" -o table
~~~

Name          Location     SKU
------------  -----------  ------------
cptdazpl2025  northeurope  Standard_LRS

## Verify if private endpoint has been created

~~~powershell
az network private-endpoint list -g $prefix --query "[].{Name:name, Location:location, PrivateLinkServiceConnections:privateLinkServiceConnections[].name}" -o table
~~~

Name          Location
------------  -----------
cptdazpl2025  northeurope

## Verify if private dns zone entries exist after policy deployment

~~~powershell
az network private-dns record-set a list --zone-name $privateDnsZoneName -g $prefix --query "[].{Name:name, IP:aRecords[0].ipv4Address}" -o table
~~~

Name          IP
------------  --------
cptdazpl2025  10.1.0.5

> NOTE: This is going to take a while before showing up.

## Get active logs related to policy activities under the resource group

~~~powershell
# retrieve user manaaged identity id which is used by the policy assignment
$umidName="cptdazpl-policy-identity"
$umidPrincipalId=az identity show -g $prefix -n $umidName --query principalId -o tsv
az monitor activity-log list -g $prefix --offset 1h --caller $umidPrincipalId > output.activityLogs.DINE.principal.json
# find all correlationId in file output.activityLogs.DINE.principal.json.
$correlationIds = (Get-Content output.activityLogs.DINE.principal.json | ConvertFrom-Json) | Select-Object -ExpandProperty correlationId | Sort-Object -Unique
# Iterate through all `$correlationIds` and execute the `az monitor activity-log list` command for each:
foreach ($correlationId in $correlationIds) {
  $outputFile = "output.activityLogs.DINE.correlationid.$correlationId.json"
  az monitor activity-log list -g $prefix --offset 1h --correlation-id $correlationId > $outputFile
}
~~~

## Use Azure VM Serial Console to verify if private endpoint DNS entries are available

~~~powershell
az vm run-command invoke -g $prefix -n ${prefix}spoke1 --command-id RunShellScript --scripts "dig cptdazpl2025.blob.privatelink.blob.core.windows.net" --query "value[].message" -o tsv
~~~

~~~bash
Enable succeeded:
[stdout]

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> cptdazpl2025.blob.core.windows.net
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41248
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;cptdazpl2025.blob.core.windows.net. IN A

;; ANSWER SECTION:
cptdazpl2025.blob.core.windows.net. 60 IN CNAME cptdazpl2025.privatelink.blob.core.windows.net.
cptdazpl2025.privatelink.blob.core.windows.net. 9 IN A 10.1.0.5

;; Query time: 4 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Tue Jul 15 12:49:52 UTC 2025
;; MSG SIZE  rcvd: 118
~~~

## Cleanup

~~~powershell
az group delete -n $prefix --yes --no-wait
~~~

## Misc

### Where does DINE gets the Location Value from?

In the policy definition, the location parameter gets its value from:

~~~json
// line 99
"location": {
  "value": "[field('location')]"
}
~~~

Explanation:
field('location') Function: This Azure Policy function dynamically retrieves the location property from the resource that triggered the policy evaluation.

Resource Context: When the policy is evaluated, it examines resources of type Microsoft.Network/privateEndpoints (as specified in the policy's if condition). 

~~~json
"policyRule": {
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Network/privateEndpoints"
      },
~~~

For each private endpoint resource that matches the policy criteria, the field('location') function extracts the Azure region where that specific private endpoint is deployed.

Dynamic Value: The location is not hardcoded but dynamically determined based on the actual resource being evaluated.

For example:

If a private endpoint is created in East US, field('location') returns "eastus"

If a private endpoint is created in West Europe, field('location') returns "westeurope"

Usage in Deployment: This location value is then passed to the ARM template deployment within the policy, ensuring that the Microsoft.Network/privateEndpoints/privateDnsZoneGroups resource is created in the same region as the private endpoint that triggered the policy.

Example Flow:
User creates a private endpoint in East US 2
Policy is triggered and evaluates the private endpoint
field('location') returns "eastus2"
The policy's deployment template uses this location to create the DNS zone group in East US 2

### Verify if policys set "Deploy-Private-DNS-Zones" has been created

~~~powershell
az policy set-definition list --query "[?contains(name, 'Deploy-Private-DNS-Zones')]" > Deploy-Private-DNS-Zones.json
az policy set-definition list --query "[?contains(name, 'Deploy-Private-DNS-Zones')].{Name:name, id:id}"
~~~

~~~json
[
  {
    "Name": "Deploy-Private-DNS-Zones",
    "id": "/subscriptions/11c61beb-b32b-4166-9d6c-74cb3a2e04da/providers/Microsoft.Authorization/policySetDefinitions/Deploy-Private-DNS-Zones"
  }
]
~~~

Our Azure Policy Set Definition is created and the definition is located at Subscription Scope.

> NOTE: In case you like to lookup the policy definition via the Azure Portal, make sure to choose the corresponding Subscription as scope. If you choose the Root Management Group, you will not find the policy definition.