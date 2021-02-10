#-----------------------------------------------------------------------------------------------------------------
# Create security outbound network
resource "azurerm_resource_group" "security_outbound_rg" {
  name     = "${var.global_prefix}${var.security_outbound_prefix}-rg"
  location = var.location
}

module "security_outbound_vnet" {
  source              = "./modules/vnet/"
  name                = "${var.security_outbound_prefix}-vnet"
  vnet_cidr           = var.security_outbound_vnet_cidr
  subnet_names        = var.security_outbound_subnet_names
  subnet_cidrs        = var.security_outbound_subnet_cidrs
  location            = var.location
  resource_group_name = azurerm_resource_group.security_outbound_rg.name
}

#-----------------------------------------------------------------------------------------------------------------
# Create storage account and file share for bootstrapping

resource "random_string" "security_outbound" {
  length      = 15
  min_lower   = 5
  min_numeric = 10
  special     = false
}

resource "azurerm_storage_account" "security_outbound_storage" {
  name                     = "outbound${random_string.security_outbound.result}"
  resource_group_name      = azurerm_resource_group.security_outbound_rg.name
  location                 = azurerm_resource_group.security_outbound_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

module "security_outbound_fileshare" {
  source               = "./modules/azure_bootstrap/"
  name                 = "${var.security_outbound_prefix}-bootstrap"
  quota                = 1
  storage_account_name = azurerm_storage_account.security_outbound_storage.name
  storage_account_key  = azurerm_storage_account.security_outbound_storage.primary_access_key
  local_file_path      = "bootstrap_files/security_outbound_fw/"
}

#-----------------------------------------------------------------------------------------------------------------
# Create internal load balancer. Load balancer uses firewall's trust interfaces as its backend pool

module "security_outbound_intlb" {
  source                = "./modules/lb/"
  name                  = "${var.security_outbound_prefix}-internal-lb"
  resource_group_name   = azurerm_resource_group.security_outbound_rg.name
  location              = azurerm_resource_group.security_outbound_rg.location
  type                  = "private"
  sku                   = "Standard"
  probe_ports           = [22]
  frontend_ports        = [0]
  backend_ports         = [0]
  protocol              = "All"
  subnet_id             = module.security_outbound_vnet.subnet_ids[2]
  private_ip_address    = var.security_outbound_lb_ip
  network_interface_ids = module.security_outbound_fw.nic2_id
}

#-----------------------------------------------------------------------------------------------------------------
# Create VM-Series.  For every fw_name entered, an additional VM-Series instance will be deployed.

module "security_outbound_fw" {
  source                    = "./modules/vmseries/"
  name                      = "${var.security_outbound_prefix}-vm"
  resource_group_name       = azurerm_resource_group.security_outbound_rg.name
  location                  = azurerm_resource_group.security_outbound_rg.location
  vm_count                  = var.fw_vm_count
  username                  = var.vm_username
  password                  = var.vm_password
  panos                     = var.fw_panos
  offer                     = var.fw_offer
  license                   = var.fw_license
  nsg_prefix                = var.fw_nsg_prefix
  avset_name                = "${var.security_outbound_prefix}-avset"
  subnet_mgmt               = module.security_outbound_vnet.subnet_ids[0]
  subnet_untrust            = module.security_outbound_vnet.subnet_ids[1]
  subnet_trust              = module.security_outbound_vnet.subnet_ids[2]
  nic0_public_ip            = true
  nic1_public_ip            = true
  nic2_public_ip            = false
  nic1_backend_pool_id      = []
  nic2_backend_pool_id      = [module.security_outbound_intlb.backend_pool_id]
  bootstrap_storage_account = azurerm_storage_account.security_outbound_storage.name
  bootstrap_access_key      = azurerm_storage_account.security_outbound_storage.primary_access_key
  bootstrap_file_share      = module.security_outbound_fileshare.file_share_name
  bootstrap_share_directory = "None"


  dependencies = [
    module.security_outbound_fileshare.completion
  ]
}


output "MGMT-OUTBOUND-FW1" {
  value = "https://${module.security_outbound_fw.nic0_public_ip[0]}"
}

output "MGMT-OUTBOUND-FW2" {
  value = "https://${module.security_outbound_fw.nic0_public_ip[1]}"
}
