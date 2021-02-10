#-----------------------------------------------------------------------------------------------------------------
# Create spoke VNET that is connected directly to the virtual hub
resource "azurerm_resource_group" "spoke_wan_rg" {
  name     = "${var.global_prefix}${var.spoke_wan_prefix}-rg"
  location = var.location
}

module "spoke_wan_vnet" {
  source              = "./modules/vnet/"
  name                = "${var.spoke_wan_prefix}-vnet"
  vnet_cidr           = var.spoke_wan_vnet_cidr
  subnet_names        = var.spoke_wan_subnet_names
  subnet_cidrs        = var.spoke_wan_subnet_cidrs
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke_wan_rg.name
}

data "template_file" "web_startup" {
  template = file("${path.module}/scripts/web_startup.yml.tpl")

  # depends_on = [
  #   azurerm_virtual_hub.wan,
  #   azurerm_virtual_hub_route_table.wan_rtb,
  #   azurerm_virtual_hub_connection.security_outbound.conn,
  #   azurerm_virtual_hub_connection.spoke_wan_conn
  # ]
}

module "spoke_wan_vm" {
  source              = "./modules/spoke_vm/"
  name                = "${var.spoke_wan_prefix}-vm"
  resource_group_name = azurerm_resource_group.spoke_wan_rg.name
  location            = var.location
  vm_count            = var.spoke_wan_vm_count
  subnet_id           = module.spoke_wan_vnet.subnet_ids[0]
  availability_set_id = ""
  publisher           = "Canonical"
  offer               = "UbuntuServer"
  sku                 = "16.04-LTS"
  public_ip           = false
  custom_data         = base64encode(data.template_file.web_startup.rendered)
  username            = var.vm_username
  password            = var.vm_password
  tags                = var.tags
}