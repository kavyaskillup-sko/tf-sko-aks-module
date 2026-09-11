# Route table that forces all egress traffic from private subnets through
# Azure Firewall (hub-and-spoke / forced tunneling pattern).

resource "azurerm_route_table" "this" {
  name                          = "rt-${var.name_prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each       = toset(var.subnet_ids)
  subnet_id      = each.value
  route_table_id = azurerm_route_table.this.id
}
