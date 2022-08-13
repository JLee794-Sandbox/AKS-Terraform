resource "azurerm_resource_group" "this" {
  name     = "aks-tf-labs-01"
  location = "Central US"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "lab01-demo-cluster"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "dev" // Or whichever environment naming convention you would like to use for sandboxing/development
    Automation = "Terraform"
    Owner = "resourceOwner@myCompany.com"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.this.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}

output "id" {
  description = "The Kubernetes Managed Cluster ID."
  value = azurerm_kubernetes_cluster.this.id
}