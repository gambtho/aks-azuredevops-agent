resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.name}-aks"
  location            = "${data.azurerm_resource_group.main.location}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  dns_prefix          = "${var.name}"
  kubernetes_version  = "${var.kubernetes_version}"

  agent_pool_profile {
    name            = "nodepool"
    count           = "${var.agents_count}"
    vm_size         = "${var.agents_size}"
    os_type         = "Linux"
    os_disk_size_gb = 50
  }

  network_profile {
    network_plugin = "kubenet"
  }

  service_principal {
    client_id     = "${var.service_principal_client_id}"
    client_secret = "${var.service_principal_client_secret}"
  }
}

data "azurerm_resource_group" "main" {
  name = "${var.name}"
}