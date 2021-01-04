resource "azurerm_resource_group" "wan" {
  name     = "${var.global_prefix}${var.wan_prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_wan" "wan" {
  name                = var.wan_prefix
  resource_group_name = azurerm_resource_group.wan.name
  location            = azurerm_resource_group.wan.location
}

resource "azurerm_virtual_hub" "wan" {
  name                = "${var.location}-hub"
  resource_group_name = azurerm_resource_group.wan.name
  location            = azurerm_resource_group.wan.location
  virtual_wan_id      = azurerm_virtual_wan.wan.id
  address_prefix      = var.wan_hub_cidr
  sku                 = "Standard"
}

resource "azurerm_virtual_hub_route_table" "wan_rtb" {
  name           = "${azurerm_virtual_hub.wan.name}-rtb"
  virtual_hub_id = azurerm_virtual_hub.wan.id
  labels         = ["spoke"]

  route {
    name              = "route0"
    destinations_type = "CIDR"
    destinations      = [var.spoke_local_vnet_cidr]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_virtual_hub_connection.security_outbound_conn.id
  }

}

resource "azurerm_virtual_hub_connection" "security_outbound_conn" {
  name                      = "${var.security_outbound_prefix}-conn"
  virtual_hub_id            = azurerm_virtual_hub.wan.id
  remote_virtual_network_id = module.security_outbound_vnet.vnet_id

  routing {
    propagated_route_table {
      labels = ["default"]
    }

    static_vnet_route {
      name = "route0"
      address_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      next_hop_ip_address = var.security_outbound_lb_ip
    }
  }

}

resource "azurerm_virtual_hub_connection" "security_inbound_conn" {
  name                      = "${var.security_inbound_prefix}-conn"
  virtual_hub_id            = azurerm_virtual_hub.wan.id
  remote_virtual_network_id = module.security_inbound_vnet.vnet_id

  routing {

    propagated_route_table {
      labels = ["default", "spoke"]
    }
  }

}

resource "azurerm_virtual_hub_connection" "spoke_wan_conn" {
  name                      = "${var.spoke_wan_prefix}-conn"
  virtual_hub_id            = azurerm_virtual_hub.wan.id
  remote_virtual_network_id = module.spoke_wan_vnet.vnet_id

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.wan_rtb.id
    
    propagated_route_table {
      labels          = ["default", "spoke"]
      route_table_ids = [azurerm_virtual_hub_route_table.wan_rtb.id]
    }
  }

}

