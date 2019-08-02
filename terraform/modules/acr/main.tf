resource "azurerm_container_registry" "acr" {
  name                = "${var.name}"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  sku                 = "Premium"
  admin_enabled       = false
}

data "azurerm_resource_group" "main" {
  name = "${var.name}"
}