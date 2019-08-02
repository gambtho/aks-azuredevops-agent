provider "azurerm" {
  version         = "1.32.0"
  tenant_id       = "${var.tenant}"
  subscription_id = "${var.subscription}"
  client_id       = "${var.ARM_CLIENT_ID}"
  client_secret   = "${var.ARM_CLIENT_SECRET}"
}

data "azurerm_resource_group" "main" {
  name = "${var.name}"
}

module "kubernetes" {
  source                          = "./modules/kubernetes-cluster"
  name                            = "${data.azurerm_resource_group.main.name}"
  agents_size                     = "${var.agents_size}"
  agents_count                    = "${var.agents_count}"
  kubernetes_version              = "${var.kubernetes_version}"
  service_principal_client_id     = "${var.ARM_CLIENT_ID}"
  service_principal_client_secret = "${var.ARM_CLIENT_SECRET}"
  client_app_id                   = "${var.client_app_id}"
  server_app_id                   = "${var.server_app_id}"
  server_app_secret               = "${var.server_app_secret}"
}

module "acr" {
  source = "./modules/acr"
  name   = "${data.azurerm_resource_group.main.name}"
}

terraform {
  backend "azurerm" {}
}
