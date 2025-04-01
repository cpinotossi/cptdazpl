data "azurerm_network_watcher" "network_watcher" {
  name                = "NetworkWatcher_germanywestcentral"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_virtual_machine_extension" "spoke1_windows_vm_extension" {
  name                 = "${var.prefix}s1"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke1_windows_vm.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"
  depends_on           = [azurerm_windows_virtual_machine.spoke1_windows_vm]
}

resource "azurerm_virtual_machine_extension" "spoke2_windows_vm_extension" {
  name                 = "${var.prefix}s2"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke2_windows_vm.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"
  depends_on           = [azurerm_windows_virtual_machine.spoke2_windows_vm]
}

resource "azurerm_virtual_machine_extension" "spoke1_linux_vm_extension" {
  name                 = "${var.prefix}s1linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.spoke1_linux_vm.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"
  depends_on           = [azurerm_linux_virtual_machine.spoke1_linux_vm]
}

resource "azurerm_virtual_machine_extension" "spoke2_linux_vm_extension" {
  name                 = "${var.prefix}s2linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.spoke2_linux_vm.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentLinux"
  type_handler_version = "1.4"
  depends_on           = [azurerm_linux_virtual_machine.spoke2_linux_vm]
}

resource "azurerm_network_connection_monitor" "example" {
  name               = var.prefix
  network_watcher_id = data.azurerm_network_watcher.network_watcher.id
  location           = var.location

  endpoint {
    name                 = "spoke1"
    target_resource_id   = azurerm_windows_virtual_machine.spoke1_windows_vm.id
    target_resource_type = "AzureVM"
  }
  endpoint {
    name                 = "spoke2"
    target_resource_id   = azurerm_windows_virtual_machine.spoke2_windows_vm.id
    target_resource_type = "AzureVM"
  }
  endpoint {
    name                 = "spoke1linux"
    target_resource_id   = azurerm_linux_virtual_machine.spoke1_linux_vm.id
    target_resource_type = "AzureVM"
  }
  endpoint {
    name                 = "spoke2linux"
    target_resource_id   = azurerm_linux_virtual_machine.spoke2_linux_vm.id
    target_resource_type = "AzureVM"
  }
  endpoint {
    name                 = "ifconfigio"
    address              = "ifconfig.io"
    target_resource_type = "ExternalAddress"
  }
  test_configuration {
    name                      = "icmp"
    protocol                  = "Icmp"
    test_frequency_in_seconds = 30
    icmp_configuration {
      trace_route_enabled = true
    }
  }
  test_configuration {
    name                      = "http"
    protocol                  = "Http"
    test_frequency_in_seconds = 30
    preferred_ip_version      = "IPv4"
    http_configuration {
      port   = 443
      method = "Get"
      # path               = "/"
      prefer_https             = true
      valid_status_code_ranges = ["200"]
    }
  }
  test_group {
    name                     = "spoke1-to-spoke2"
    destination_endpoints    = ["spoke2"]
    source_endpoints         = ["spoke1"]
    test_configuration_names = ["icmp"]
  }
  test_group {
    name                     = "spoke1-to-spoke2-linux"
    destination_endpoints    = ["spoke2linux"]
    source_endpoints         = ["spoke1linux"]
    test_configuration_names = ["icmp"]
  }
  test_group {
    name                     = "spoke1-linux-to-ifconfigio"
    destination_endpoints    = ["ifconfigio"]
    source_endpoints         = ["spoke1linux"]
    test_configuration_names = ["http"]
  }
  test_group {
    name                     = "spoke2-linux-to-ifconfigio"
    destination_endpoints    = ["ifconfigio"]
    source_endpoints         = ["spoke2linux"]
    test_configuration_names = ["http"]
  }
  output_workspace_resource_ids = [azurerm_log_analytics_workspace.log_analytics.id]
}