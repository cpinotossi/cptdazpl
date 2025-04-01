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

resource "azurerm_monitor_private_link_scoped_service" "ampls_scope" {
  name                = var.prefix
  resource_group_name = azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.log_analytics.id
}

resource "azurerm_private_endpoint" "pe" {
  name                = var.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  # subnet_id           = "${azurerm_virtual_network.hub1.id}/subnets/${var.prefix}"
  subnet_id = azurerm_subnet.hub1_subnet.id

  private_service_connection {
    name                           = var.prefix
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false # Does the Private Endpoint require Manual Approval from the remote resource owner? Changing this forces a new resource to be created.
  }
  private_dns_zone_group {
    name                 = var.prefix
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_monitor_azure_com.id, azurerm_private_dns_zone.privatelink_oms_opinsights_azure_com.id, azurerm_private_dns_zone.privatelink_ods_opinsights_azure_com.id, azurerm_private_dns_zone.privatelink_agentsvc_azure_automation_net.id, azurerm_private_dns_zone.privatelink_blob_core_windows_net.id]
  }

  custom_network_interface_name = "${var.prefix}ampls"
}

resource "azurerm_private_dns_zone" "privatelink_monitor_azure_com" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_oms_opinsights_azure_com" {
  name                = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_ods_opinsights_azure_com" {
  name                = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_agentsvc_azure_automation_net" {
  name                = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link_spoke1_ampls" {
  for_each = {
    spoke1_monitor_azure_com_name             = azurerm_private_dns_zone.privatelink_monitor_azure_com.name
    spoke1_oms_opinsights_azure_com_name      = azurerm_private_dns_zone.privatelink_oms_opinsights_azure_com.name
    spoke1_ods_opinsights_azure_com_name      = azurerm_private_dns_zone.privatelink_ods_opinsights_azure_com.name
    spoke1_agentsvc_azure_automation_net_name = azurerm_private_dns_zone.privatelink_agentsvc_azure_automation_net.name
    spoke1_blob_core_windows_net_name         = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
  }

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.spoke1.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link_spoke2_ampls" {
  for_each = {
    spoke2_monitor_azure_com_name             = azurerm_private_dns_zone.privatelink_monitor_azure_com.name
    spoke2_oms_opinsights_azure_com_name      = azurerm_private_dns_zone.privatelink_oms_opinsights_azure_com.name
    spoke2_ods_opinsights_azure_com_name      = azurerm_private_dns_zone.privatelink_ods_opinsights_azure_com.name
    spoke2_agentsvc_azure_automation_net_name = azurerm_private_dns_zone.privatelink_agentsvc_azure_automation_net.name
    spoke2_blob_core_windows_net_name         = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
  }

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.spoke2.id
}

resource "azurerm_role_assignment" "vm_law_reader" {
  for_each = {
    hub1_linux_vm          = azurerm_linux_virtual_machine.hub1_linux_vm.identity[0].principal_id
    hub2_linux_vm          = azurerm_linux_virtual_machine.hub2_linux_vm.identity[0].principal_id
    spoke1_linux_vm        = azurerm_linux_virtual_machine.spoke1_linux_vm.identity[0].principal_id
    spoke1_windows_vm      = azurerm_windows_virtual_machine.spoke1_windows_vm.identity[0].principal_id
    spoke2_linux_vm        = azurerm_linux_virtual_machine.spoke2_linux_vm.identity[0].principal_id
    spoke2_windows_vm      = azurerm_windows_virtual_machine.spoke2_windows_vm.identity[0].principal_id
    current_user_object_id = data.azuread_user.current_user_object_id.object_id
  }

  principal_id         = each.value
  role_definition_name = "Log Analytics Reader"
  scope                = azurerm_log_analytics_workspace.log_analytics.id
}
