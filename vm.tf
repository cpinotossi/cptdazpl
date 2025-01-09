resource "azurerm_network_interface" "hub1_linux_nic" {
  name                = "${var.prefix}hub1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub1_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke1_windows_nic" {
  name                = "${var.prefix}spoke1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke1_linux_nic" {
  name                = "${var.prefix}spoke1linux"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "hub2_linux_nic" {
  name                = "${var.prefix}hub2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub2_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke2_windows_nic" {
  name                = "${var.prefix}spoke2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "spoke2_linux_nic" {
  name                = "${var.prefix}spoke2linux"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "hub1_linux_vm" {
  name                            = "${var.prefix}h1linux"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = base64encode(var.vm_custom_data_linux)
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.hub1_linux_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}

resource "azurerm_linux_virtual_machine" "hub2_linux_vm" {
  name                            = "${var.prefix}h2linux"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = base64encode(var.vm_custom_data_linux)
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.hub2_linux_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}


resource "azurerm_windows_virtual_machine" "spoke1_windows_vm" {
  name                = "${var.prefix}s1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.spoke1_windows_nic.id,
  ]
  custom_data = base64encode("<powershell>\nInvoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile AzureCLI.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait; Remove-Item -Force AzureCLI.msi\n</powershell>")
  os_disk {
    storage_account_type = "Standard_LRS"
    name                 = "${var.prefix}spoke1"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-23h2-pro"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}

resource "azurerm_linux_virtual_machine" "spoke1_linux_vm" {
  name                            = "${var.prefix}s1linux"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = base64encode(var.vm_custom_data_linux)
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.spoke1_linux_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}

resource "azurerm_windows_virtual_machine" "spoke2_windows_vm" {
  name                = "${var.prefix}s2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.spoke2_windows_nic.id,
  ]
  custom_data = base64encode("<powershell>\nInvoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile AzureCLI.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet' -Wait; Remove-Item -Force AzureCLI.msi\n</powershell>")
  os_disk {
    storage_account_type = "Standard_LRS"
    name                 = "${var.prefix}spoke2"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-23h2-pro"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}

resource "azurerm_linux_virtual_machine" "spoke2_linux_vm" {
  name                            = "${var.prefix}s2linux"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = var.username
  admin_password                  = var.password
  custom_data                     = base64encode(var.vm_custom_data_linux)
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.spoke2_linux_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  boot_diagnostics {
  }
}

resource "azurerm_virtual_machine_extension" "spoke1_windows_vm_disable_firewall" {
  name                 = "${var.prefix}s1-disable-firewall"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke1_windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
        {
                "commandToExecute": "netsh advfirewall firewall add rule name=\"ICMP Allow incoming V4 echo request\" protocol=\"icmpv4:8,any\" dir=in action=allow"
        }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "spoke2_windows_vm_disable_firewall" {
  name                 = "${var.prefix}s2-disable-firewall"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke2_windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
        {
                "commandToExecute": "netsh advfirewall firewall add rule name=\"ICMP Allow incoming V4 echo request\" protocol=\"icmpv4:8,any\" dir=in action=allow"
        }
SETTINGS
}

