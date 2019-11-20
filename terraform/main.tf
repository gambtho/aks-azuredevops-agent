provider "azurerm" {
  version         = "1.32.0"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.arm_client_id}"
  client_secret   = "${var.arm_client_secret}"
  partner_id      = "a79fe048-6869-45ac-8683-7fd2446fc73c"
}

data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

module "kubernetes" {
  source                          = "./modules/kubernetes-cluster"
  name                            = "${data.azurerm_resource_group.main.name}"
  agents_size                     = "${var.agents_size}"
  agents_count                    = "${var.agents_count}"
  kubernetes_version              = "${var.kubernetes_version}"
  service_principal_client_id     = "${var.arm_client_id}"
  service_principal_client_secret = "${var.arm_client_secret}"
}

module "acr" {
  source = "./modules/acr"
  name   = "${data.azurerm_resource_group.main.name}"
}

terraform {
  backend "azurerm" {}
}
