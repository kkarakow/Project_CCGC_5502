resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = var.network_config.address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  for_each            = { for idx, subnet_name in var.network_config.subnet_names : subnet_name => idx }
  name                = var.network_config.subnet_names[each.value]
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.network_config.subnet_prefixes[each.value]]
}
