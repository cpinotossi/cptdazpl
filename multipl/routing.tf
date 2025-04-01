# routing -----------------------------------------------------------------------------------------------
resource "azurerm_route_table" "hub1_route_table" {
  name                = "${var.prefix}hub1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# resource "azurerm_route" "hub1_to_hub2" {
#   name                   = "hub1-to-hub2"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.hub1_route_table.name
#   address_prefix         = var.cidrs["hub2"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
# }

# resource "azurerm_route" "hub1_to_spoke1" {
#   name                   = "hub1-to-spoke1"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.hub1_route_table.name
#   address_prefix         = var.cidrs["spoke1"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
# }

# resource "azurerm_route" "hub1_to_hub1_shared_services" {
#   name                   = "hub1-to-hub1-shared-services"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.hub1_route_table.name
#   address_prefix         = var.cidrs["hub1"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
# }

resource "azurerm_route" "hub1_to_spoke2" {
  name                   = "hub1-to-spoke2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub1_route_table.name
  address_prefix         = var.cidrs["hub2_summary_cidr"]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
}
resource "azurerm_subnet_route_table_association" "hub1_fw_route_table_association" {
  subnet_id      = azurerm_subnet.hub1_fw_subnet.id
  route_table_id = azurerm_route_table.hub1_route_table.id
}

resource "azurerm_subnet_route_table_association" "hub1_vm_route_table_association" {
  subnet_id      = azurerm_subnet.hub1_subnet.id
  route_table_id = azurerm_route_table.hub1_route_table.id
}

resource "azurerm_route_table" "hub2_route_table" {
  name                = "${var.prefix}hub2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# resource "azurerm_route" "hub2_to_hub1" {
#   name                   = "hub2-to-hub1"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.hub2_route_table.name
#   address_prefix         = var.cidrs["hub1"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
# }

resource "azurerm_route" "hub2_to_spoke1" {
  name                   = "hub2-to-spoke1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.hub2_route_table.name
  address_prefix         = var.cidrs["hub1_summary_cidr"]
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
}

# resource "azurerm_route" "hub2_to_spoke2" {
#   name                   = "hub1-to-spoke2"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.hub2_route_table.name
#   address_prefix         = var.cidrs["spoke2"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
# }

resource "azurerm_subnet_route_table_association" "hub2_fw_route_table_association" {
  subnet_id      = azurerm_subnet.hub2_fw_subnet.id
  route_table_id = azurerm_route_table.hub2_route_table.id
}

resource "azurerm_subnet_route_table_association" "hub2_vm_route_table_association" {
  subnet_id      = azurerm_subnet.hub2_subnet.id
  route_table_id = azurerm_route_table.hub2_route_table.id
}

# spoke1 route table

resource "azurerm_route_table" "spoke1_route_table" {
  name                          = "${var.prefix}spoke1"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "spoke1_to_spoke2" {
  name                = "spoke1-to-spoke2"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.spoke1_route_table.name
  address_prefix      = var.cidrs["spoke2"]
  #   address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
}

# resource "azurerm_route" "spoke1_to_hub1" {
#   name                   = "spoke1-to-hub1"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.spoke1_route_table.name
#   address_prefix         = var.cidrs["hub1"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
# }

# resource "azurerm_route" "spoke1_to_hub2" {
#   name                   = "spoke1-to-hub2"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.spoke1_route_table.name
#   address_prefix         = var.cidrs["hub2"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub1_firewall.ip_configuration[0].private_ip_address
# }

resource "azurerm_subnet_route_table_association" "spoke1_route_table_association" {
  subnet_id      = azurerm_subnet.spoke1_subnet.id
  route_table_id = azurerm_route_table.spoke1_route_table.id
}

resource "azurerm_route_table" "spoke2_route_table" {
  name                          = "${var.prefix}spoke2"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "spoke2_to_spoke1" {
  name                = "spoke2-to-spoke1"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.spoke2_route_table.name
  address_prefix      = var.cidrs["spoke1"]
  #   address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke2_to_hub1_private_endpoint" {
  name                = "spoke2-to-hub1-private-endpoint"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.spoke2_route_table.name
  address_prefix      = var.cidrs["hub1"]
  #   address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
}

# resource "azurerm_route" "spoke2_to_hub1" {
#   name                   = "spoke2-to-hub1"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.spoke2_route_table.name
#   address_prefix         = var.cidrs["hub1"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
# }

# resource "azurerm_route" "spoke2_to_hub2" {
#   name                   = "spoke2-to-hub2"
#   resource_group_name    = azurerm_resource_group.rg.name
#   route_table_name       = azurerm_route_table.spoke2_route_table.name
#   address_prefix         = var.cidrs["hub2"]
#   next_hop_type          = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_firewall.hub2_firewall.ip_configuration[0].private_ip_address
# }

resource "azurerm_subnet_route_table_association" "spoke2_route_table_association" {
  subnet_id      = azurerm_subnet.spoke2_subnet.id
  route_table_id = azurerm_route_table.spoke2_route_table.id
}