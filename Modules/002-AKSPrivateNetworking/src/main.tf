resource "azurerm_resource_group" "this" {
  name     = "aks-tf-labs-02"
  location = "Central US"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "lab02-demo-private-cluster"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ########################################
  # Section 2.2 BEGIN
  ########################################
  load_balancer_sku = "standard"
  private_cluster_enabled = true
  network_profile {
      network_plugin = "azure"
  }
  vnet_subnet_id = "<subnet-id>"
  docker_bridge_cidr = "172.17.0.1/16"
  dns_service_ip = "10.2.0.10"
  service_cidr = "10.2.0.0/24"
  identity {
      type = "UserAssigned"
      identity_ids = ["<ResourceId>"]
  }
  private_dns_zone_id = "System | None | <DNS Zone Resource ID>"
  private_cluster_public_fqdn_enabled = false
  ########################################
  # Section 2.2 END
  ########################################

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
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