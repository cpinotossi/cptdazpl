# - Using previously-installed hashicorp/azuread v3.0.2
# - Using previously-installed hashicorp/azurerm v4.14.0

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

data "azuread_user" "current_user_object_id" {
  object_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.prefix
  location = var.location
}

variable "cidrs" {
  description = "Configuration for the Virtual Machines"
  type        = map(string)
  default = {
    hub1_summary_cidr   = "10.0.0.0/16"
    hub1                = "10.0.0.0/22"
    spoke1              = "10.0.4.0/22"
    hub1_subnet         = "10.0.0.0/24"
    hub1_fw_subnet      = "10.0.1.0/24"
    hub1_fw_mgmt_subnet = "10.0.2.0/24"
    hub1_bastion_subnet = "10.0.3.0/24"
    spoke1_subnet       = "10.0.4.0/24"
    hub2_summary_cidr   = "192.168.0.0/16"
    hub2                = "192.168.0.0/22"
    spoke2              = "192.168.4.0/22"
    hub2_subnet         = "192.168.0.0/24"
    hub2_fw_subnet      = "192.168.1.0/24"
    hub2_fw_mgmt_subnet = "192.168.2.0/24"
    spoke2_subnet       = "192.168.4.0/24"
  }
}

resource "azurerm_virtual_network" "hub1" {
  name                = "${var.prefix}hub1"
  address_space       = [var.cidrs["hub1"]]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "spoke1" {
  name                = "${var.prefix}spoke1"
  address_space       = [var.cidrs["spoke1"]]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "hub2" {
  name                = "${var.prefix}hub2"
  address_space       = [var.cidrs["hub2"]]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "${var.prefix}spoke2"
  address_space       = [var.cidrs["spoke2"]]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "hub1_subnet" {
  name                 = "${var.prefix}hub1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub1.name
  address_prefixes     = [var.cidrs["hub1_subnet"]]
}

resource "azurerm_subnet" "hub1_fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub1.name
  address_prefixes     = [var.cidrs["hub1_fw_subnet"]]
}

resource "azurerm_subnet" "hub1_fw_mgmt_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub1.name
  address_prefixes     = [var.cidrs["hub1_fw_mgmt_subnet"]]
}

resource "azurerm_subnet" "hub1_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub1.name
  address_prefixes     = [var.cidrs["hub1_bastion_subnet"]]
}

resource "azurerm_subnet" "spoke1_subnet" {
  name                 = "${var.prefix}spoke1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.cidrs["spoke1_subnet"]]
}


resource "azurerm_subnet" "hub2_subnet" {
  name                 = "${var.prefix}hub2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub2.name
  address_prefixes     = [var.cidrs["hub2_subnet"]]
}

resource "azurerm_subnet" "hub2_fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub2.name
  address_prefixes     = [var.cidrs["hub2_fw_subnet"]]
}

resource "azurerm_subnet" "hub2_fw_mgmt_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub2.name
  address_prefixes     = [var.cidrs["hub2_fw_mgmt_subnet"]]
}

resource "azurerm_subnet" "spoke2_subnet" {
  name                 = "${var.prefix}spoke2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = [var.cidrs["spoke2_subnet"]]
}

# Peering ------------------------------------------------------------------------------

resource "azurerm_virtual_network_peering" "hub1_to_hub2" {
  name                         = "${var.prefix}hub1-to-hub2"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub1.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub1_to_spoke1" {
  name                         = "${var.prefix}hub1-to-spoke1"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub1.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub1" {
  name                         = "${var.prefix}spoke1-to-hub1"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub2_to_hub1" {
  name                         = "${var.prefix}hub2-to-hub1"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub2_to_spoke2" {
  name                         = "${var.prefix}hub2-to-spoke2"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub2.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub2" {
  name                         = "${var.prefix}spoke2-to-hub2"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# NSG ------------------------------------------------------------------------------

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-ICMP-Inbound-Hub1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP-Inbound-Hub2"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP-Outbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# resource "azurerm_subnet_network_security_group_association" "hub1_fw_subnet_nsg" {
#     subnet_id                 = azurerm_subnet.hub1_fw_subnet.id
#     network_security_group_id = azurerm_network_security_group.nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "hub1_fw_mgmt_subnet_nsg" {
#     subnet_id                 = azurerm_subnet.hub1_fw_mgmt_subnet.id
#     network_security_group_id = azurerm_network_security_group.nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "hub1_bastion_subnet_nsg" {
#     subnet_id                 = azurerm_subnet.hub1_bastion_subnet.id
#     network_security_group_id = azurerm_network_security_group.nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "hub2_fw_subnet_nsg" {
#     subnet_id                 = azurerm_subnet.hub2_fw_subnet.id
#     network_security_group_id = azurerm_network_security_group.nsg.id
# }

# resource "azurerm_subnet_network_security_group_association" "hub2_fw_mgmt_subnet_nsg" {
#     subnet_id                 = azurerm_subnet.hub2_fw_mgmt_subnet.id
#     network_security_group_id = azurerm_network_security_group.nsg.id
# }

resource "azurerm_subnet_network_security_group_association" "hub1_subnet_nsg" {
  subnet_id                 = azurerm_subnet.hub1_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub2_subnet_nsg" {
  subnet_id                 = azurerm_subnet.hub2_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1_subnet_nsg" {
  subnet_id                 = azurerm_subnet.spoke1_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2_subnet_nsg" {
  subnet_id                 = azurerm_subnet.spoke2_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# resource "azurerm_bastion_host" "bastion" {
#   name                = var.prefix
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Standard"
#   ip_connect_enabled  = true
#   tunneling_enabled   = true
#   ip_configuration {
#     name                 = "${var.prefix}bastion"
#     subnet_id            = azurerm_subnet.hub1_bastion_subnet.id
#     public_ip_address_id = azurerm_public_ip.bastion.id
#   }
# }

# resource "azurerm_public_ip" "bastion" {
#   name                = "${var.prefix}bastion"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }