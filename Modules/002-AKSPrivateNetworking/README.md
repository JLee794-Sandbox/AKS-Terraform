# Learning Module 002 - AKS Private Networking

This section will be building on the Terraform configuration in the [previous lab](../001-BaseAKSDeployment/src) to go through the steps outlined within the [Create a private Azure Kubernetes Service cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters) document and implement the same process in Terraform.

## Table of Contents

- [Learning Module 002 - AKS Private Networking](#learning-module-002---aks-private-networking)
  - [Table of Contents](#table-of-contents)
  - [Learning Objectives](#learning-objectives)
  - [Private AKS Cluster Overview](#private-aks-cluster-overview)
  - [Section 1 - Gather Requirements for a Base Private AKS Cluster](#section-1---gather-requirements-for-a-base-private-aks-cluster)
    - [Section 1 Learning Objectives](#section-1-learning-objectives)
    - [Steps](#steps)
  - [Section 2 - Update Terraform Configuration with Captured Requirements](#section-2---update-terraform-configuration-with-captured-requirements)
    - [Section 2 Learning Objectives](#section-2-learning-objectives)
    - [Steps](#steps-1)

## Learning Objectives

- Translating infrastructure requirements into Terraform
- Adding additional components into a single deployment file

## Private AKS Cluster Overview

In a private cluster, the control plane or API server has internal IP addresses that are defined in the [RFC1918 - Address Allocation for Private Internet](https://tools.ietf.org/html/rfc1918) document. By using a private cluster, you can ensure network traffic between your API server and your node pools remains on the private network only.

The control plane or API server is in an Azure Kubernetes Service (AKS)-managed Azure subscription. A customer's cluster or node pool is in the customer's subscription. The server and the cluster or node pool can communicate with each other through the [Azure Private Link service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview#limitations) in the API server virtual network and a private endpoint that's exposed in the subnet of the customer's AKS cluster.

When you provision a private AKS cluster, AKS by default creates a private FQDN with a private DNS zone and an additional public FQDN with a corresponding A record in Azure public DNS. The agent nodes still use the A record in the private DNS zone to resolve the private IP address of the private endpoint for communication to the API server.

## Section 1 - Gather Requirements for a Base Private AKS Cluster

This section aims to walk through an example scenario of how you can plan and begin to build your own custom Terraform configuration based on process documentation such as the [Create a Private Cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters) document.

### Section 1 Learning Objectives

- Capturing requirements before building Terraform code
- Looking up configuration in Terraform documentation

### Steps

1. Navigate to the [Create a Private Cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters#create-a-private-aks-cluster) section within the [Create a private Azure Kubernetes Service cluster](https://docs.microsoft.com/en-us/azure/aks/private-clusters#create-a-private-aks-cluster) Microsoft document.
2. Capture requirements within the [Advanced Networking](https://docs.microsoft.com/en-us/azure/aks/private-clusters#advanced-networking) section:

   ```bash
   az aks create \
   --resource-group <private-cluster-resource-group> \
   --name <private-cluster-name> \
   --load-balancer-sku standard \           # capture in tf
   --enable-private-cluster \               # capture in tf
   --network-plugin azure \                 # capture in tf
   --vnet-subnet-id <subnet-id> \           # capture in tf 
   --docker-bridge-address 172.17.0.1/16 \  # capture in tf
   --dns-service-ip 10.2.0.10 \             # capture in tf
   --service-cidr 10.2.0.0/24               # capture in tf
   ```

3. Capture requirements within [Disable Public FQDN](https://docs.microsoft.com/en-us/azure/aks/private-clusters#disable-public-fqdn) section:

   ```bash
   az aks create \
     -n <private-cluster-name> \
     -g <private-cluster-resource-group> \
     --load-balancer-sku standard \
     --enable-private-cluster \
     --enable-managed-identity \                  # capture in tf
     --assign-identity <ResourceId> \             # capture in tf
     --private-dns-zone <private-dns-zone-mode> \ # capture in tf
     --disable-public-fqdn                        # capture in tf
   ```

4. Look up the requirements/flags captured from the previous steps on the [terraform aks resource documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster). For this lab, refer to the table below for the mapping.

   | Captured Requirement | AKS Terraform Argument | Terraform Argument Description |
   | ---------------------------------- | -------------------------- | --------------- |
   |  `--load-balancer-sku standard`    | [load_balancer_sku = "standard"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#load_balancer_sku) | (Optional) Specifies the SKU of the Load Balancer used for this Kubernetes Cluster. Possible values are `basic` and `standard`. Defaults to `standard`. |
   | `--enable-private-cluster`         | [private_cluster_enabled = true](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_cluster_enabled) | (Optional) Should this Kubernetes Cluster have its API server only exposed on internal IP addresses? This provides a Private IP Address for the Kubernetes API on the Virtual Network where the Kubernetes Cluster is located. Defaults to `false`. **Changing this forces a new resource to be created.** |
   | `network-plugin azure` |  `network_profile` {<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[network_plugin = "azure"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#network_plugin)<br />} | (Required) Network plugin to use for networking. Currently supported values are `azure`, `kubenet` and `none`. **Changing this forces a new resource to be created.** |
   | `--vnet-subnet-id <subnet-id>` | [vnet_subnet_id = "\<subnet-id\>"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#vnet_subnet_id) | (Optional) The ID of a Subnet where the Kubernetes Node Pool should exist. **Changing this forces a new resource to be created.** |
   | `--docker-bridge-address 172.17.0.1/16` | [docker_bridge_cidr = "172.17.0.1/16"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#docker_bridge_cidr) | (Optional) IP address (in CIDR notation) used as the Docker bridge IP address on nodes. **Changing this forces a new resource to be created.** |
   | `--dns-service-ip 10.2.0.10` | [dns_service_ip = "10.2.0.10](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#dns_service_ip) | (Optional) IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns). **Changing this forces a new resource to be created.** |
   | `--service-cidr 10.2.0.0/24` | [service_cidr = "10.2.0.0/24"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#service_cidr) | (Optional) The Network Range used by the Kubernetes service. **Changing this forces a new resource to be created.** |
   | `--enable-managed-identity` </br></br> `--assign-identity <ResourceId>` | `identity` {<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[type = "UserAssigned"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#identity_ids)<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[identity_ids = ["\<ResourceId\>"]](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#identity_ids) <br/> } | (Required - `type`) Specifies the type of Managed Service Identity that should be configured on this Kubernetes Cluster. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned (to enable both). <br /> <br /> (Optional - `identity_ids`) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Kubernetes Cluster.|
   | `--private-dns-zone <private-dns-zone-mode>` | [private_dns_zone_id = "System \| None \| \<DNS Zone Resource ID\>"](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_dns_zone_id) | (Optional) Either the `ID of Private DNS Zone` which should be delegated to this Cluster, `System` to have AKS manage this or `None`. In case of None you will need to bring your own DNS server and set up resolving, otherwise cluster will have issues after provisioning. **Changing this forces a new resource to be created.** | 
   | `--disable-public-fqdn` | [private_cluster_public_fqdn_enabled = false](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_cluster_public_fqdn_enabled) | (Optional) Specifies whether a Public FQDN for this Private Cluster should be added. Defaults to `false`. |

## Section 2 - Update Terraform Configuration with Captured Requirements

Now that we have consumed the base requirements to create a Private AKS cluster resource, in this section we will be implementing that into our existing terraform files from our previous lab.


### Section 2 Learning Objectives

- Adding additional, required Terraform components
- Iteratively developing your Terraform code


### Steps

1. Review the required parameters to map from the previous section's table to determine if additional Terraform components need to be added to achieve Private AKS Cluster
    - Notes:
      - additional networking components are required to provide values for `vnet_subnet_id`
      - for providing **BOTH** system and user managed identities, the `identity` block must be set to `UserAssigned` and additional Terraform components will be required to provide the `identity_ids`.
2. [Optional] Add Networking Components
    > !!! IF you already have an existing Azure subnet you would like to use for `vnet_subnet_id`, skip this step.
     1. Look up the [Terraform documentation for `azurerm_virtual_network`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
     2. Copy the `azurerm_virtual_network` example block and configure it accordingly.
        
```hcl

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

```