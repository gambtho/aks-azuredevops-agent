
variable "name" {
  description = "The name of the Resource Group in which the Virtual Network"
}

variable "agents_count" {
  description = "The number of Agents that should exist in the Agent Pool"
}

variable "agents_size" {
  description = "The Azure VM Size of the Virtual Machines used in the Agent Pool"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to install"
}

variable "service_principal_client_id" {}

variable "service_principal_client_secret" {}
