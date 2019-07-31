
variable "name" {
  description = "resource group name"
}

# azure 

variable "ARM_CLIENT_ID" {
  description = "app id used by terraform"
}

variable "ARM_CLIENT_SECRET" {
  description = "app secret used by terraform"
}

variable "tenant" {
  description = "azure tenant id"
}

variable "subscription" {
    description = "azure subscription id"
}


# aks 
variable "agents_count" {
  description = "The number of Agents that should exist in the Agent Pool"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to install"
  default     = "1.13.7"
}

variable "agents_size" {
  description = "The default virtual machine size for the Kubernetes agents"
}

variable "client_app_id" {
    description = "app id used for AKS clients"
}
variable "server_app_id" {
    description = "app id used by AKS for AAD integration"
}

variable "server_app_secret" {
      description = "app secret used by AKS for AAD integration"
}