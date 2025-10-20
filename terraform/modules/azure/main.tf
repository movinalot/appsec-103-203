locals {
  vm_username             = var.vm_username
  password                = var.password
  rg-prefix               = var.rg-prefix
  resource_group_name     = "${local.rg-prefix}-${var.rg-suffix}"
  resource_group_location = var.location

  shared_image_versions = {
    "Client"     = { resource_group_name = "xperts-2025-appsec-103-203-utility", gallery_name = "usxperts2025", image_name = "Client", name = "latest" }
    "AppServer1" = { resource_group_name = "xperts-2025-appsec-103-203-utility", gallery_name = "usxperts2025", image_name = "AppServer1", name = "latest" }
    "AppServer2" = { resource_group_name = "xperts-2025-appsec-103-203-utility", gallery_name = "usxperts2025", image_name = "AppServer2", name = "latest" }
  }

  public_ips = {
    "Azure-Bastion-PUB" = { name = "Azure-Bastion-PUB", sku = "Standard", allocation_method = "Static", ddos_protection_mode = "Disabled" }
    "FAD-Primary-PUB"   = { name = "FAD-Primary-PUB", sku = "Standard", allocation_method = "Static", ddos_protection_mode = "Disabled" }
    "FAD-Secondary-PUB" = { name = "FAD-Secondary-PUB", sku = "Standard", allocation_method = "Static", ddos_protection_mode = "Disabled" }
    "FGT-1-PUB"         = { name = "FGT-1-PUB", sku = "Standard", allocation_method = "Static", ddos_protection_mode = "Disabled" }
  }

  subnets = {
    "APP"                = { name = "APP", address_prefix = "10.1.3.0/24" }
    "Proxy"              = { name = "Proxy", address_prefix = "10.1.2.0/24" }
    "Public"             = { name = "Public", address_prefix = "10.1.1.0/24" }
    "AzureBastionSubnet" = { name = "AzureBastionSubnet", address_prefix = "10.0.0.0/24" }
  }

  subnet_network_security_group_associations = {
    "Public" = {
      subnet_id                 = azurerm_subnet.subnet["Public"].id,
      network_security_group_id = azurerm_network_security_group.network_security_group.id
    }
    "Proxy" = {
      subnet_id                 = azurerm_subnet.subnet["Proxy"].id,
      network_security_group_id = azurerm_network_security_group.network_security_group.id
    }
    "APP" = {
      subnet_id                 = azurerm_subnet.subnet["APP"].id,
      network_security_group_id = azurerm_network_security_group.network_security_group.id
    }
  }

  storage_blobs = {
    "fad-primary-config" = {
      name                   = "fad-primary-config.txt"
      storage_account_name   = azurerm_storage_account.storage_account.name
      storage_container_name = azurerm_storage_container.storage_container.name
      type                   = "Block"
      source                 = "${path.module}/fad-primary-config.txt"
      source_content         = null
    },
    "fad-secondary-config" = {
      name                   = "fad-secondary-config.txt"
      storage_account_name   = azurerm_storage_account.storage_account.name
      storage_container_name = azurerm_storage_container.storage_container.name
      type                   = "Block"
      source                 = "${path.module}/fad-secondary-config.txt"
      source_content         = null
    }
  }

  fad-primary-cloudinit = <<CLOUDINIT
{
"storage-account" : "${azurerm_storage_account.storage_account.name}",
"container" : "${azurerm_storage_container.storage_container.name}",
"config" : "fad-primary-config.txt",
"flex_token": "${var.fortiflexvm_token_adc_1}"
}
CLOUDINIT

  fad-secondary-cloudinit = <<CLOUDINIT
{
"storage-account" : "${azurerm_storage_account.storage_account.name}",
"container" : "${azurerm_storage_container.storage_container.name}",
"config" : "fad-secondary-config.txt",
"flex_token": "${var.fortiflexvm_token_adc_2}"
}
CLOUDINIT

  bastion_hosts = {
    "bastion-host" = {
      resource_group_name = azurerm_resource_group.resource_group.name
      location            = azurerm_resource_group.resource_group.location

      name                   = "bastion-host"
      sku                    = "Standard"
      shareable_link_enabled = true

      ip_configuration = {
        name                 = "ipconfig1"
        subnet_id            = azurerm_subnet.subnet["AzureBastionSubnet"].id
        public_ip_address_id = azurerm_public_ip.public_ip["Azure-Bastion-PUB"].id
      }
    }
  }

  resource_action_create_links = {
    create_link = {
      type        = "Microsoft.Network/bastionHosts@2022-05-01"
      name        = "createLink"
      resource_id = azurerm_bastion_host.bastion_host["bastion-host"].id
      action      = "createShareableLinks"
      body = {
        vms = [
          {
            vm = {
              id = azurerm_linux_virtual_machine.client.id
            }
          }
        ]
      }
    }
  }

  resource_action_get_links = {
    get_link = {
      type                   = "Microsoft.Network/bastionHosts@2022-05-01"
      name                   = "getLink"
      resource_id            = azurerm_bastion_host.bastion_host["bastion-host"].id
      action                 = "getShareableLinks"
      response_export_values = ["*"]
    }
  }
}

data "azurerm_subscription" "subscription" {}

resource "random_id" "id" {

  keepers = {
    resource_group_name = format("%s", local.resource_group_name)
  }

  byte_length = 4
}

resource "azurerm_resource_group" "resource_group" {
  name     = local.resource_group_name
  location = local.resource_group_location

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_storage_account" "storage_account" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = format("%s%s", local.rg-prefix, random_id.id.hex)

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {

  name                  = "fad-config"
  storage_account_id    = azurerm_storage_account.storage_account.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "storage_blob" {

  for_each = local.storage_blobs

  name                   = each.value.name
  storage_account_name   = each.value.storage_account_name
  storage_container_name = each.value.storage_container_name
  type                   = each.value.type
  source                 = each.value.source
  source_content         = each.value.source_content
}

data "azurerm_shared_image_version" "shared_image_version" {
  for_each = local.shared_image_versions

  resource_group_name = each.value.resource_group_name
  gallery_name        = each.value.gallery_name
  image_name          = each.value.image_name
  name                = each.value.name

}

resource "azurerm_public_ip" "public_ip" {
  for_each = local.public_ips

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                 = each.value.name
  allocation_method    = each.value.allocation_method
  ddos_protection_mode = each.value.ddos_protection_mode
}

resource "azurerm_network_security_group" "network_security_group" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "AppSec103-203-FortiADC-nsg"
}

resource "azurerm_network_security_rule" "network_security_rule_egress" {

  resource_group_name = azurerm_resource_group.resource_group.name

  name = "Allow-Internet-Egress"

  network_security_group_name = azurerm_network_security_group.network_security_group.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "network_security_rule_ingress" {

  resource_group_name = azurerm_resource_group.resource_group.name

  name = "Allow-Internet-Ingress"

  network_security_group_name = azurerm_network_security_group.network_security_group.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_virtual_network" "virtual_network" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  address_space = ["10.0.0.0/16", "10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

  name = "AppSec103-203-FortiADC-vnet"
}

resource "azurerm_subnet" "subnet" {
  for_each = local.subnets

  resource_group_name = azurerm_resource_group.resource_group.name

  name             = each.value.name
  address_prefixes = [each.value.address_prefix]

  virtual_network_name = azurerm_virtual_network.virtual_network.name
}

resource "azurerm_network_interface" "network_interface-app-server-1" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "APP-Server1"

  ip_configuration {
    name                          = "Ipv4config"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["APP"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["APP"].address_prefixes)[0], 4)
    public_ip_address_id          = null
  }
}

resource "azurerm_network_interface" "network_interface-app-server-2" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "APP-Server2"

  ip_configuration {
    name                          = "Ipv4config"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["APP"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["APP"].address_prefixes)[0], 5)
    public_ip_address_id          = null
  }
}

resource "azurerm_network_interface" "network_interface-client" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                  = "Client"
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "Ipv4config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet["Public"].id
    public_ip_address_id          = null
  }
}

resource "azurerm_network_interface" "network_interface-fad-primary-p1" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                  = "FAD-Primary-p1"
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "Ipv4config"
    primary                       = true
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 50)
    public_ip_address_id          = azurerm_public_ip.public_ip["FAD-Primary-PUB"].id
  }
  ip_configuration {
    name                          = "Juiceshop"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 100)
  }
  ip_configuration {
    name                          = "DVWA"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 101)
  }
}

resource "azurerm_network_interface" "network_interface-fad-primary-p2" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Primary-p2"

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["APP"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["APP"].address_prefixes)[0], 100)
  }
}

resource "azurerm_network_interface" "network_interface-fad-secondary-p1" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                  = "FAD-Secondary-p1"
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "Ipv4config"
    primary                       = true
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 51)
    public_ip_address_id          = azurerm_public_ip.public_ip["FAD-Secondary-PUB"].id
  }
  ip_configuration {
    name                          = "Juiceshop"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 110)
  }
  ip_configuration {
    name                          = "DVWA"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 111)
  }
}

resource "azurerm_network_interface" "network_interface-fad-secondary-p2" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Secondary-p2"

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["APP"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["APP"].address_prefixes)[0], 101)
  }
}

resource "azurerm_network_interface" "network_interface-fgt-1-p1" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                  = "FGT-1-p1"
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "Ipv4config"
    primary                       = true
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Public"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Public"].address_prefixes)[0], 6)
    public_ip_address_id          = azurerm_public_ip.public_ip["FGT-1-PUB"].id
  }
  ip_configuration {
    name                          = "Juiceshop"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Public"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Public"].address_prefixes)[0], 100)
  }
  ip_configuration {
    name                          = "DVWA"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Public"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Public"].address_prefixes)[0], 101)
  }

}

resource "azurerm_network_interface" "network_interface-fgt-1-p2" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FGT-1-p2"

  ip_configuration {
    name                          = "ipconfig1"
    primary                       = true
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.subnet["Proxy"].id
    private_ip_address            = cidrhost(tolist(azurerm_subnet.subnet["Proxy"].address_prefixes)[0], 254)
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_network_security_group_association" {
  for_each = local.subnet_network_security_group_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.network_security_group_id
}

resource "azurerm_linux_virtual_machine" "fgtvm" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name                            = "FGT-1"
  network_interface_ids           = [azurerm_network_interface.network_interface-fgt-1-p1.id, azurerm_network_interface.network_interface-fgt-1-p2.id]
  size                            = "Standard_D2s_v4"
  disable_password_authentication = false

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = "fortinet_fg-vm_payg_2023_g2"
    version   = "latest"
  }

  plan {
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm_v5"
    name      = "fortinet_fg-vm_payg_2023_g2"
  }

  os_disk {
    name                 = "FGT-1_OsDisk_1"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  admin_username = local.vm_username
  admin_password = local.password

  custom_data = base64encode(templatefile("${path.module}/fortios.tpl", {
    fgt_vm_name           = "FGT-1"
    fgt_license_file      = ""
    fgt_license_fortiflex = ""
    fgt_username          = local.vm_username
    fgt_ssh_public_key    = ""
  }))

  boot_diagnostics {
  }
}

resource "azurerm_linux_virtual_machine" "app-server-1" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "APP-Server1"

  admin_password                  = local.password
  admin_username                  = local.vm_username
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.network_interface-app-server-1.id]
  secure_boot_enabled   = true
  size                  = "Standard_D2s_v4"

  vtpm_enabled = true

  additional_capabilities {
  }
  boot_diagnostics {
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_id = data.azurerm_shared_image_version.shared_image_version["AppServer1"].id
}

resource "azurerm_linux_virtual_machine" "app-server-2" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "APP-Server2"

  admin_password                  = local.password
  admin_username                  = local.vm_username
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.network_interface-app-server-2.id]
  secure_boot_enabled   = true
  size                  = "Standard_D2s_v4"

  vtpm_enabled = true

  additional_capabilities {
  }
  boot_diagnostics {
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_id = data.azurerm_shared_image_version.shared_image_version["AppServer2"].id
}


resource "azurerm_linux_virtual_machine" "client" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "Client"

  admin_password                  = local.password
  admin_username                  = local.vm_username
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.network_interface-client.id]

  secure_boot_enabled = true
  size                = "Standard_D4s_v4"

  vtpm_enabled = true

  additional_capabilities {
  }
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_id = data.azurerm_shared_image_version.shared_image_version["Client"].id
}

resource "azurerm_linux_virtual_machine" "fad-primary" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Primary"

  admin_password                  = local.password
  admin_username                  = local.vm_username
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.network_interface-fad-primary-p1.id, azurerm_network_interface.network_interface-fad-primary-p2.id]

  size = "Standard_D4s_v4"

  additional_capabilities {
  }
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  plan {
    name      = "fad-vm-byol"
    product   = "fortinet-fortiadc"
    publisher = "fortinet"
  }
  source_image_reference {
    offer     = "fortinet-fortiadc"
    publisher = "fortinet"
    sku       = "fad-vm-byol"
    version   = "8.0.0"
  }
  custom_data = base64encode(local.fad-primary-cloudinit)
}

resource "azurerm_managed_disk" "managed_disk-fad-primary" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Primary_DataDisk_0"

  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  os_type              = "Linux"
  depends_on           = [azurerm_linux_virtual_machine.fad-primary]
}

resource "azurerm_virtual_machine_data_disk_attachment" "fad-primary-data-disk-attachment" {
  caching            = "ReadWrite"
  lun                = 0
  managed_disk_id    = azurerm_managed_disk.managed_disk-fad-primary.id
  virtual_machine_id = azurerm_linux_virtual_machine.fad-primary.id
}

resource "azurerm_linux_virtual_machine" "fad-secondary" {

  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Secondary"

  admin_password                  = local.password
  admin_username                  = local.vm_username
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.network_interface-fad-secondary-p1.id, azurerm_network_interface.network_interface-fad-secondary-p2.id]

  size = "Standard_D4s_v4"

  additional_capabilities {
  }
  boot_diagnostics {
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  plan {
    name      = "fad-vm-byol"
    product   = "fortinet-fortiadc"
    publisher = "fortinet"
  }
  source_image_reference {
    offer     = "fortinet-fortiadc"
    publisher = "fortinet"
    sku       = "fad-vm-byol"
    version   = "latest"
  }
  custom_data = base64encode(local.fad-secondary-cloudinit)
}

resource "azurerm_managed_disk" "managed_disk-fad-secondary" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  name = "FAD-Secondary_DataDisk_0"

  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  os_type              = "Linux"
}

resource "azurerm_virtual_machine_data_disk_attachment" "fad-secondary-data-disk-attachment" {
  caching            = "None"
  lun                = 0
  managed_disk_id    = azurerm_managed_disk.managed_disk-fad-secondary.id
  virtual_machine_id = azurerm_linux_virtual_machine.fad-secondary.id
}

resource "azurerm_bastion_host" "bastion_host" {
  for_each = local.bastion_hosts

  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  name                   = each.value.name
  sku                    = each.value.sku
  shareable_link_enabled = each.value.shareable_link_enabled

  ip_configuration {
    name                 = each.value.ip_configuration.name
    subnet_id            = each.value.ip_configuration.subnet_id
    public_ip_address_id = each.value.ip_configuration.public_ip_address_id
  }
}

resource "azapi_resource_action" "resource_action_create_link" {
  for_each = local.resource_action_create_links

  type        = each.value.type
  resource_id = each.value.resource_id
  action      = each.value.action
  body        = each.value.body
}

data "azapi_resource_action" "resource_action_get_link" {
  for_each = local.resource_action_get_links

  type                   = each.value.type
  resource_id            = each.value.resource_id
  action                 = each.value.action
  response_export_values = each.value.response_export_values
  depends_on             = [azapi_resource_action.resource_action_create_link["create_link"]]
}

output "bastion_shareable_links" {
  value = data.azapi_resource_action.resource_action_get_link["get_link"].output
}
