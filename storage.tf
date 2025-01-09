resource "azurerm_storage_account" "storage" {
  name                      = "${var.prefix}storage"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  shared_access_key_enabled = true
}

resource "azurerm_storage_container" "container" {
  name = var.prefix
  #   storage_account_name  = azurerm_storage_account.storage.name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "myfile.vhd"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "spiderman.txt"
}

resource "azurerm_role_assignment" "vm_blob_contributor" {
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
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.storage.id
}


