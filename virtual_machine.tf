# -----------------------------------------------------------------------------
# Azure VM
# -----------------------------------------------------------------------------

# Create NIC
resource "azurerm_network_interface" "nic" {
  name                = var.nic.name
  location            = var.location != "" ? var.location : data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = var.nic.ip_configuration.name
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = var.nic.ip_configuration.private_ip_address_allocation
  }
}

# Create Azure Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = var.linux_vm.name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = var.location != "" ? var.location : data.azurerm_resource_group.resource_group.location
  size                = var.linux_vm.size
  admin_username      = var.linux_vm.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.linux_vm.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = var.linux_vm.os_disk.caching
    storage_account_type = var.linux_vm.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.linux_vm.source_image_reference.publisher
    offer     = var.linux_vm.source_image_reference.offer
    sku       = var.linux_vm.source_image_reference.sku
    version   = var.linux_vm.source_image_reference.version
  }
}
