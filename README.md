# Azure Monitor Private Link Service [AMPLS]

## Hub and Spoke and AMPLS

> NOTE: The Hub and Spoke architecture is based on the work done here: [Hub and Spoke](https://github.com/davmhelm/azure-multi-region-hub-and-spoke).

> NOTE: We expect that you already have an existing "Network Watch" at the corresponding regions.

Create the hub and spoke architecture with the following components via terraform:

~~~powershell
az account set --subscription sub-cptdx-01
# Set the current Azure subscription as an environment variable
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv
tf init
tf fmt
tf validate
tf plan -out=tfplan1
tf apply --auto-approve tfplan1 
~~~

### Connection Manager

After we have deployed the hub and spoke architecture we will be able to retrieve network watcher connection monirtor test results via our new log analytics workspace.

Retrieve the Log Analytis Workspace id.

~~~powershell
$location1="germanywestcentral"
$prefix="cptdazpl"
$lawguid=az monitor log-analytics workspace list -g $prefix --query [].customerId -o tsv
$lawid=az monitor log-analytics workspace show -g $prefix -n $prefix --query id -o tsv
~~~

Verify if test have been deployed.

~~~ bash
az network watcher connection-monitor list -l $location1 -o table
~~~

~~~console
ConnectionMonitorType    Location            Name      ProvisioningState    ResourceGroup     StartTime
-----------------------  ------------------  --------  -------------------  ----------------  ----------------------------
MultiEndpoint            germanywestcentral  cptdazpl  Succeeded            NetworkWatcherRG  2025-01-07T13:11:16.6884409Z
~~~

Define new variables to query the connection-monitor results.

~~~ bash
$query="NWConnectionMonitorTestResult | where TimeGenerated >= ago(10min) | project TestGroupName, TestConfigurationName, SourceIP,DestinationIP,TestResult| summarize by TestResult,TestGroupName,SourceIP,DestinationIP"
~~~

Let´s have a look at our connection manager test results.

~~~powershell
az monitor log-analytics query -w $lawguid --analytics-query "$query" -o table
~~~

~~~console
DestinationIP    SourceIP     TableName      TestGroupName               TestResult
---------------  -----------  -------------  --------------------------  ------------
192.168.4.4      10.0.4.5     PrimaryResult  spoke1-to-spoke2-linux      Pass
188.114.97.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
188.114.96.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
188.114.97.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
188.114.96.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
~~~

### AMPLS

~~~mermaid
classDiagram
    Hub1 <|-- Spoke1
    Hub2 <|-- Spoke2
    Hub1 <|-- Hub2
    Hub1 : Firewall 10.0.1.4
    Hub1: PrivateEndpoint 10.0.0.4
    Hub1: VM 10.0.0.15
    Hub2 : Firewall 192.168.1.4
    Hub2 : VM 192.168.0.4
    class Spoke1{
      VM 10.0.4.5
    }
    class Spoke2{
      VM 192.168.4.4
    }
~~~

- We created an Azure Private Endpoint for Azure Monitor which has been places in a Subnet inside Hub1.
- Hub1 is accessible from Spoke1, Spoke2 and Hub2
- We created an Azure Monitor Private Link Service (AMPLS) which is assigned to the Private Endpoint.
- We created an Loga nalytics Workspace which is assigned to the AMPLS.
- The private endpoint does use the following internal ips:

~~~powershell
# List all private DNS records of all private DNS zones inside the resource group
$zones = az network private-dns zone list --resource-group $prefix --query "[].name" -o tsv
foreach ($zone in $zones) {
    az network private-dns record-set list --resource-group $prefix --zone-name $zone --query "[?type=='Microsoft.Network/privateDnsZones/A'].aRecords[].ipv4Address" -o table
}
~~~

~~~console
Result
---------
10.0.0.14
Result
---------
10.0.0.10
Result
---------
10.0.0.5
10.0.0.4
10.0.0.11
10.0.0.8
10.0.0.7
10.0.0.6
10.0.0.9
Result
---------
10.0.0.13
Result
---------
10.0.0.12
~~~

- We did link Private Endpoints IPs via corresponding Private DNS Zones to Spoke1 and Spoke2.

~~~powershell
# List all virtual networks linked to all private DNS zones inside the resource group
$zones = az network private-dns zone list --resource-group $prefix --query "[].name" -o tsv
foreach ($zone in $zones) {
    az network private-dns link vnet list --resource-group $prefix --zone-name $zone --query "[].{name:name,vnet:virtualNetwork.id}" -o tsv | foreach { $_ -replace '/subscriptions/[^/]*/', '' } | Format-Table
}
~~~

~~~console
spoke1_agentsvc_azure_automation_net_name       resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke1
spoke2_agentsvc_azure_automation_net_name       resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke2
spoke1_blob_core_windows_net_name       resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke1
spoke2_blob_core_windows_net_name       resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke2
spoke1_monitor_azure_com_name   resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke1
spoke2_monitor_azure_com_name   resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke2
spoke1_ods_opinsights_azure_com_name    resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke1
spoke2_ods_opinsights_azure_com_name    resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke2
spoke1_oms_opinsights_azure_com_name    resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke1
spoke2_oms_opinsights_azure_com_name    resourceGroups/cptdazpl/providers/Microsoft.Network/virtualNetworks/cptdazplspoke2
~~~

#### Test#1 AMPLS access mode open

Query results from network watcher connection monitor which are located inside the log analytics workspace which is assigend to the AMPLS fron my local machine, connected via public internet.

AMPLS is setup with query_access_mode Open and log analytics workspace internet_ery_enabled true so we expect to see the results.

~~~hcl
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                       = var.prefix
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku                        = "PerGB2018"
  internet_ingestion_enabled = true
  internet_query_enabled     = true
}

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                  = var.prefix
  resource_group_name   = azurerm_resource_group.rg.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "Open"
}
~~~

~~~powershell
az monitor log-analytics query -w $lawguid --analytics-query "$query" -o table
~~~

~~~console
DestinationIP    SourceIP     TableName      TestGroupName               TestResult
---------------  -----------  -------------  --------------------------  ------------
188.114.96.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
192.168.4.4      10.0.4.5     PrimaryResult  spoke1-to-spoke2-linux      Pass
188.114.97.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
188.114.97.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
188.114.96.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
~~~

#### Test#1 AMPLS access mode private

Query results from network watcher connection monitor which are located inside the log analytics workspace which is assigend to the AMPLS fron my local machine, connected via public internet.

AMPLS is setup with query_access_mode PrivateOnly and log analytics workspace internet_ery_enabled false so we expect a deny.

~~~hcl
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                       = var.prefix
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku                        = "PerGB2018"
  internet_ingestion_enabled = true
  internet_query_enabled     = false
}

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                  = var.prefix
  resource_group_name   = azurerm_resource_group.rg.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}
~~~

Call the query from my local machine.

~~~powershell
az monitor log-analytics query -w $lawguid --analytics-query "$query" -o table --debug
~~~

~~~console
(InsufficientAccessError) The provided credentials have insufficient access to perform the requested operation
Code: InsufficientAccessError
Message: The provided credentials have insufficient access to perform the requested operation
Inner error: {
    "code": "NspValidationFailedError",
    "message": "Access to workspace 'cptdazpl' from '172.201.77.43' is denied. To allow access from public networks, change the workspace Networking settings or add it to a Network Security Perimeter. (workspace resource ID: /subscriptions/resourceGroups/cptdazpl/providers/microsoft.operationalinsights/workspaces/cptdazpl)"
}
~~~

NOTE: The Request has been send to the Azure Monitor Endpoint 'https://api.loganalytics.io/ which does point to api.monitor.azure.com.

This becomes more visiable if we do an nslookup for api.loganalytics.io

~~~powershell
nslookup api.loganalytics.io
Server:  fritz.box
Address:  192.168.178.1

Non-authoritative answer:
Name:    commoninfra-prod-dewc-0-ingress-draft.germanywestcentral.cloudapp.azure.com
Address:  20.218.184.197
Aliases:  api.loganalytics.io
          api.monitor.azure.com
          api.privatelink.monitor.azure.com
          draftprodglobal.trafficmanager.net
~~~

#### Test#1 AMPLS access mode private from spoke vms

Inside both linux spoke vms we will see different results for our DNS query.

~~~bash
dig api.loganalytics.io
~~~

~~~console
;; ANSWER SECTION:
api.loganalytics.io.    81      IN      CNAME   api.monitor.azure.com.
api.monitor.azure.com.  114     IN      CNAME   api.privatelink.monitor.azure.com.
api.privatelink.monitor.azure.com. 10 IN A      10.0.0.4
~~~

Execute the query from both spoke vms via the serial console.

~~~bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az extension add --name log-analytics
az login --identity
prefix="cptdazpl"
lawguid=$(az monitor log-analytics workspace list -g $prefix --query [].customerId -o tsv)
query="NWConnectionMonitorTestResult | where TimeGenerated >= ago(10min) | project TestGroupName, TestConfigurationName, SourceIP,DestinationIP,TestResult| summarize by TestResult,TestGroupName,SourceIP,DestinationIP"
az monitor log-analytics query -w $lawguid --analytics-query "$query" -o table --debug
~~~

Both time we have the same results.

~~~console
DestinationIP    SourceIP     TableName      TestGroupName               TestResult
---------------  -----------  -------------  --------------------------  ------------
192.168.4.4      10.0.4.5     PrimaryResult  spoke1-to-spoke2-linux      Pass
188.114.96.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
188.114.97.3     10.0.4.5     PrimaryResult  spoke1-linux-to-ifconfigio  Pass
188.114.97.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
188.114.96.3     192.168.4.4  PrimaryResult  spoke2-linux-to-ifconfigio  Pass
~~~

#### AMPLS Routing

By introducing a private endpoint in hub1 the corresponding routing table will be populate with [optional default routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview#optional-default-routes) which can be seen via the effective routes of the vms in hub1, hub2 and spoke1

~~~powershell
# Loop through each NIC and list its effective routes
$nics = az network nic list -g $prefix --query [].name -o tsv
foreach ($nicname in $nics) {
    Write-Output "$nicname effective routes:"
    az network nic show-effective-route-table -g $prefix --name $nicname --output table
    Write-Output ""
}
~~~

~~~console
cptdazplhub1 effective routes:
Source    State    Address Prefix    Next Hop Type      Next Hop IP
--------  -------  ----------------  -----------------  -------------
Default   Active   10.0.0.0/22       VnetLocal
Default   Active   192.168.0.0/22    VNetPeering
Default   Active   10.0.4.0/22       VNetPeering
Default   Active   0.0.0.0/0         Internet
User      Active   192.168.0.0/16    VirtualAppliance   192.168.1.4
Default   Active   10.0.0.11/32      InterfaceEndpoint
Default   Active   10.0.0.10/32      InterfaceEndpoint
Default   Active   10.0.0.9/32       InterfaceEndpoint
Default   Active   10.0.0.8/32       InterfaceEndpoint
Default   Active   10.0.0.7/32       InterfaceEndpoint
Default   Active   10.0.0.6/32       InterfaceEndpoint
Default   Active   10.0.0.5/32       InterfaceEndpoint
Default   Active   10.0.0.4/32       InterfaceEndpoint
Default   Active   10.0.0.14/32      InterfaceEndpoint
Default   Active   10.0.0.13/32      InterfaceEndpoint
Default   Active   10.0.0.12/32      InterfaceEndpoint

cptdazplhub2 effective routes:
Source    State    Address Prefix    Next Hop Type      Next Hop IP
--------  -------  ----------------  -----------------  -------------
Default   Active   192.168.0.0/22    VnetLocal
Default   Active   192.168.4.0/22    VNetPeering
Default   Active   10.0.0.0/22       VNetPeering
Default   Active   0.0.0.0/0         Internet
User      Active   10.0.0.0/16       VirtualAppliance   10.0.1.4
Default   Active   10.0.0.11/32      InterfaceEndpoint
Default   Active   10.0.0.10/32      InterfaceEndpoint
Default   Active   10.0.0.9/32       InterfaceEndpoint
Default   Active   10.0.0.8/32       InterfaceEndpoint
Default   Active   10.0.0.7/32       InterfaceEndpoint
Default   Active   10.0.0.6/32       InterfaceEndpoint
Default   Active   10.0.0.5/32       InterfaceEndpoint
Default   Active   10.0.0.4/32       InterfaceEndpoint
Default   Active   10.0.0.14/32      InterfaceEndpoint
Default   Active   10.0.0.13/32      InterfaceEndpoint
Default   Active   10.0.0.12/32      InterfaceEndpoint

cptdazplspoke1linux effective routes:
Source    State    Address Prefix    Next Hop Type      Next Hop IP
--------  -------  ----------------  -----------------  -------------
Default   Active   10.0.4.0/22       VnetLocal
Default   Active   10.0.0.0/22       VNetPeering
Default   Active   0.0.0.0/0         Internet
User      Active   192.168.4.0/22    VirtualAppliance   10.0.1.4
Default   Active   10.0.0.11/32      InterfaceEndpoint
Default   Active   10.0.0.10/32      InterfaceEndpoint
Default   Active   10.0.0.9/32       InterfaceEndpoint
Default   Active   10.0.0.8/32       InterfaceEndpoint
Default   Active   10.0.0.7/32       InterfaceEndpoint
Default   Active   10.0.0.6/32       InterfaceEndpoint
Default   Active   10.0.0.5/32       InterfaceEndpoint
Default   Active   10.0.0.4/32       InterfaceEndpoint
Default   Active   10.0.0.14/32      InterfaceEndpoint
Default   Active   10.0.0.13/32      InterfaceEndpoint
Default   Active   10.0.0.12/32      InterfaceEndpoint

cptdazplspoke2linux effective routes:
Source    State    Address Prefix    Next Hop Type     Next Hop IP
--------  -------  ----------------  ----------------  -------------
Default   Active   192.168.4.0/22    VnetLocal
Default   Active   192.168.0.0/22    VNetPeering
Default   Active   0.0.0.0/0         Internet
User      Active   10.0.4.0/22       VirtualAppliance  192.168.1.4
User      Active   10.0.0.0/22       VirtualAppliance  192.168.1.4
~~~

Only Spoke1, Hub1 and Hub2 will show InterfaceEndpoint routes. Spoke2, which is not connected via direct vnet peering to hub1 will not be modified.

The challenge which this setup is that we do bypass the firewall in hub1. If we need to make sure that all traffic will get inspected by the firewall we have to options:

1. [/32 Routing overide](https://youtu.be/xlf_UzTDXfo?t=419)
    - The official recommendation here is to use application rules inside the azure firewall to allow traffic to reach the private endpoint.
2. [Private Link Network Policies for UDR](https://youtu.be/xlf_UzTDXfo?t=727)

