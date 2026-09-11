data "azurerm_client_config" "current" {}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix            = local.name_prefix
  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  retention_days         = var.log_retention_days
  alert_email_addresses  = var.security_alert_email_addresses
  tags                   = local.tags
}

module "network" {
  source = "./modules/network"

  name_prefix                = local.name_prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  address_space               = var.vnet_address_space
  subnets                     = var.subnets
  enable_ddos_protection      = var.enable_ddos_protection
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  tags                        = local.tags
}

# --- Least-privilege NSGs on workload subnets (Azure restricts custom NSGs
# on AzureFirewallSubnet, so it is intentionally excluded here; egress from
# that subnet is controlled by the firewall policy itself). ---
module "nsg_aks" {
  source = "./modules/nsg"

  name_prefix         = local.name_prefix
  subnet_key          = "aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.subnet_ids["aks"]

  security_rules = [
    {
      name                          = "AllowVnetInbound"
      priority                      = 100
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "*"
      destination_port_ranges       = ["*"]
      source_address_prefixes       = ["VirtualNetwork"]
      destination_address_prefixes  = ["VirtualNetwork"]
    }
  ]

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

module "nsg_data" {
  source = "./modules/nsg"

  name_prefix         = local.name_prefix
  subnet_key          = "data"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.subnet_ids["data"]

  security_rules = [
    {
      name                          = "AllowAksToDataPrivateEndpoints"
      priority                      = 100
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "Tcp"
      destination_port_ranges       = ["443", "3306", "6380", "10255"]
      source_address_prefixes       = module.network.subnet_address_prefixes["aks"]
      destination_address_prefixes  = module.network.subnet_address_prefixes["data"]
    }
  ]

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

module "nsg_mysql" {
  source = "./modules/nsg"

  name_prefix         = local.name_prefix
  subnet_key          = "mysql"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.subnet_ids["mysql"]

  security_rules = [
    {
      name                          = "AllowAksToMySql"
      priority                      = 100
      direction                     = "Inbound"
      access                        = "Allow"
      protocol                      = "Tcp"
      destination_port_ranges       = ["3306"]
      source_address_prefixes       = module.network.subnet_address_prefixes["aks"]
      destination_address_prefixes  = module.network.subnet_address_prefixes["mysql"]
    }
  ]

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tags                       = local.tags
}

# --- Force all egress from private workload subnets through Azure Firewall ---
module "route_table" {
  source = "./modules/route-table"

  name_prefix          = local.name_prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  firewall_private_ip  = module.firewall.firewall_private_ip
  subnet_ids = [
    module.network.subnet_ids["aks"],
    module.network.subnet_ids["data"],
    module.network.subnet_ids["mysql"],
  ]
  tags = local.tags
}

module "firewall" {
  source = "./modules/firewall"

  name_prefix                = local.name_prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  firewall_subnet_id          = module.network.subnet_ids["firewall"]
  sku_tier                    = local.is_prod ? "Premium" : "Standard"
  threat_intelligence_mode    = local.is_prod ? "Deny" : "Alert"
  idps_mode                   = local.is_prod ? "Deny" : "Alert"
  log_analytics_workspace_id  = module.monitoring.log_analytics_workspace_id
  tags                        = local.tags

  network_rules = [
    {
      name             = "allow-dns"
      protocols        = ["UDP", "TCP"]
      source_addresses = var.vnet_address_space
      destination_addresses = ["*"]
      destination_ports = ["53"]
    },
    {
      name             = "allow-ntp"
      protocols        = ["UDP"]
      source_addresses = var.vnet_address_space
      destination_addresses = ["*"]
      destination_ports = ["123"]
    },
  ]

  application_rules = [
    {
      name              = "allow-microsoft-services"
      source_addresses  = var.vnet_address_space
      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com",
        "*.windows.net",
        "*.mcr.microsoft.com",
        "mcr.microsoft.com",
      ]
    },
    {
      name              = "allow-openedx-package-mirrors"
      source_addresses  = var.vnet_address_space
      destination_fqdns = [
        "pypi.org",
        "files.pythonhosted.org",
        "registry.npmjs.org",
        "github.com",
        "raw.githubusercontent.com",
        "objects.githubusercontent.com",
      ]
    },
  ]
}
