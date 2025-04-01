resource "azurerm_ip_group" "hub1_ip_group" {
  name                = "${var.prefix}hub1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  cidrs               = [var.cidrs["hub1_summary_cidr"]]
}

resource "azurerm_ip_group" "hub2_ip_group" {
  name                = "${var.prefix}hub2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  cidrs               = [var.cidrs["hub2_summary_cidr"]]
}

resource "azurerm_public_ip" "hub1_firewall" {
  name                = "${var.prefix}fw1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "hub1_firewall_mgmt" {
  name                = "${var.prefix}fw1mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "hub2_firewall" {
  name                = "${var.prefix}fw2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "hub2_firewall_mgmt" {
  name                = "${var.prefix}fw2mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "hub1_policy" {
  name                = "hub1-firewall-policy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
}

resource "azurerm_firewall_policy" "hub2_policy" {
  name                = "hub2-firewall-policy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
}

resource "azurerm_firewall_policy_rule_collection_group" "hub1_rule_collection_group" {
  name               = "hub1rcg"
  firewall_policy_id = azurerm_firewall_policy.hub1_policy.id
  priority           = 200
  network_rule_collection {
    name     = "hub1rc"
    action   = "Allow"
    priority = 200
    rule {
      name      = "hub1-hub2-traffic-rule"
      protocols = ["Any"]
      # source_ip_groups = [azurerm_ip_group.hub1_ip_group.id]
      source_addresses  = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_ports = ["*"]
      # destination_addresses = azurerm_ip_group.hub2_ip_group.cidrs
      destination_addresses = ["*"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "hub2_rule_collection_group" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub2_policy.id
  priority           = 200
  network_rule_collection {
    name     = "DefaultNetworkRuleCollection"
    action   = "Allow"
    priority = 200
    rule {
      name      = "hub2-hub1-traffic-rule"
      protocols = ["Any"]
      # source_ip_groups = [azurerm_ip_group.hub2_ip_group.id]
      source_addresses  = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      destination_ports = ["*"]
      # destination_addresses = azurerm_ip_group.hub1_ip_group.cidrs
      destination_addresses = ["*"]
    }
  }
}

resource "azurerm_firewall" "hub1_firewall" {
  name                = "${var.prefix}hub1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  management_ip_configuration {
    name                 = "${var.prefix}fw1mgmt"
    subnet_id            = azurerm_subnet.hub1_fw_mgmt_subnet.id
    public_ip_address_id = azurerm_public_ip.hub1_firewall_mgmt.id
  }
  ip_configuration {
    name                 = "${var.prefix}fw1"
    subnet_id            = azurerm_subnet.hub1_fw_subnet.id
    public_ip_address_id = azurerm_public_ip.hub1_firewall.id
  }
  firewall_policy_id = azurerm_firewall_policy.hub1_policy.id
}

resource "azurerm_firewall" "hub2_firewall" {
  name                = "${var.prefix}hub2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  management_ip_configuration {
    name                 = "${var.prefix}fw2mgmt"
    subnet_id            = azurerm_subnet.hub2_fw_mgmt_subnet.id
    public_ip_address_id = azurerm_public_ip.hub2_firewall_mgmt.id
  }
  ip_configuration {
    name                 = "${var.prefix}fw2"
    subnet_id            = azurerm_subnet.hub2_fw_subnet.id
    public_ip_address_id = azurerm_public_ip.hub2_firewall.id
  }
  firewall_policy_id = azurerm_firewall_policy.hub2_policy.id
}

resource "azurerm_monitor_diagnostic_setting" "hub1_firewall_logs" {
  name                       = "${var.prefix}fw1"
  target_resource_id         = azurerm_firewall.hub1_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
  enabled_log {
    category_group = "AllLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "hub2_firewall_logs" {
  name                       = "${var.prefix}fw2"
  target_resource_id         = azurerm_firewall.hub2_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
  enabled_log {
    category_group = "AllLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}