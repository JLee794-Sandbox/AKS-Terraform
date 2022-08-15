resource "azurerm_resource_group" "this" {
  name     = "aks-tf-labs-02"
  location = "Central US"
}

  ########################################
  # Section 2.2 BEGIN
  ########################################
resource "azurerm_virtual_network" "this" {
  name                = "lab02-demo-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"] 
  
  # dns_servers         = ["10.0.0.4", "10.0.0.5"] # Removing as not relevant

  subnet {
    name           = "lab02-aks-subnet"
    address_prefix = "10.0.1.0/24" # For guidance around subnet sizing, https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#plan-ip-addressing-for-your-cluster
  }

  tags = {
    Environment = "dev"
    Automation = "Terraform"
    Owner = "resourceOwner@myCompany.com"
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "lab02.demo"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "lab02-aks-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_private_dns_zone.this.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

########################################
# Section 2.2 END
########################################
resource "azurerm_kubernetes_cluster" "this" {
  name                = "lab02-demo-private-cluster"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  
  ########################################
  # Section 2.2 BEGIN
  ########################################
  dns_prefix_private_cluster = "lab02demo"

  private_cluster_enabled = true
  network_profile {
    load_balancer_sku = "standard"
    network_plugin = "azure"
    docker_bridge_cidr = "172.17.0.1/16"  # Internal CIDR range scoped to the cluster (does not have to be the same as the VNet CIDR)
    dns_service_ip = "10.0.1.10"          # Update to an IP address within the subnet CIDR
    service_cidr = "10.0.1.0/24"          # Update to the subnet CIDR
  }
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = azurerm_virtual_network.this.subnet.*.id[0]
  }

  identity {
      type = "UserAssigned"            # Set to SystemAssigned to generate a managed identity for the cluster
      identity_ids = [
        azurerm_user_assigned_identity.this.id
      ]
  }
  private_dns_zone_id = "System" # Let the AKS service generate the DNS zone ID
  private_cluster_public_fqdn_enabled = false
  ########################################
  # Section 2.2 END
  ########################################

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