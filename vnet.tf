# -----------------------------------------------------------------------------
# Azure VNet
# -----------------------------------------------------------------------------

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet.name
  address_space       = var.vnet.address_space
  location            = var.location != "" ? var.location : data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet.address_prefixes
  service_endpoints    = var.subnet.service_endpoints
}
