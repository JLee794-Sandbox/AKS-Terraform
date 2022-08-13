# Learning Module 001 - Base AKS Deployment

In this module you will be constructing a basic Terraform deployment around AKS, and how you can begin to organize and structure your code.

## Table of Contents

- [Learning Module 001 - Base AKS Deployment](#learning-module-001---base-aks-deployment)
  - [Table of Contents](#table-of-contents)
  - [Section 1 - Working with Terraform Docs](#section-1---working-with-terraform-docs)
  - [Section 2 - Configure your Terraform Azure Provider](#section-2---configure-your-terraform-azure-provider)
  - [Section 3 - Constructing AKS Terraform Template](#section-3---constructing-aks-terraform-template)
  - [Section 4 - Deploy Terraform Configuration to Azure](#section-4---deploy-terraform-configuration-to-azure)
  - [Additional Documentation Relevant to this Lab](#additional-documentation-relevant-to-this-lab)
  - [Next Steps](#next-steps)

## Section 1 - Working with Terraform Docs

---

>If your current lab environment **IS NOT** configured for Terraform and Azure CLI, please review the [Install and Configure Terraform](../000-TerraformIntroduction/README.md#install-and-configure-terraform) section on the [000-TerraformIntroduction](../000-TerraformIntroduction) lab documentation.

1. Navigate to the [Terraform documentation page for AKS](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
2. Pay attention to the main sections within the documentation:
     1. [Example Usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#example-usage) - First section you will see on all Terraform resource documentation. This will show you a basic configuration you can replicate in your current configuration.
     2. [Argument Reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#argument-reference) - This section covers the available inputs and configurations the resource accommodates. Note the abundance of configuration items and options here, not all resources for Terraform will share these many configurable items (for example, [resource groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)).
        1. Pay close attention to mentions around arguments that will cause recreates for the resource if values are changed (e.g resource names) as being careless with how you feed your configuration can cause unintended outages.
     3. [Attributes Reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#attributes-reference) - This section covers what the available object attributes are for the **provisioned resource**. These are essentially the 'outputs' from the resource itself.

## Section 2 - Configure your Terraform Azure Provider

---

Terraform relies on plugins called "providers" to interact with cloud providers, SaaS providers, and other APIs.

Terraform configurations must declare which providers they require so that Terraform can install and use them. Additionally, some providers require configuration (like endpoint URLs or cloud regions) before they can be used.

You can continue reading more about Providers in the [official Terraform documentation](https://www.terraform.io/language/providers).

1. Create your AzureRM provider configuration file
   1. Create a directory named `lab1`
   1. Within `lab1`, create a file named `provider.tf`

      ```bash
        lab1
        └── providers.tf
      ```

1. Navigate to the `Example Usage` section within the [`azurerm` provider docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) and copy the `terraform` and `provider` blocks and place them within your `providers.tf`

    ```hcl
      # We strongly recommend using the required_providers block to set the
      # Azure Provider source and version being used
      terraform {
        required_providers {
          azurerm = {
            source  = "hashicorp/azurerm"
            version = "=3.0.0"
          }
        }
      }

      # Configure the Microsoft Azure Provider
      provider "azurerm" {
        features {}
      }
    ```

1. [OPTIONAL] Configure your remote state backend with various Azure AD authentication options outlined within [azurerm backend documentation](https://www.terraform.io/language/settings/backends/azurerm).

## Section 3 - Constructing AKS Terraform Template

---

1. In your local development environment, do the following:
   1. Within `lab1`, create a file named `main.tf`
   1. Your local lab environment should now have a folder structure that looks like the following:

      ```bash
        lab1
        ├── main.tf
        └── providers.tf
      ```

1. Going back to the Terraform online documentation, on the [Example Usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#example-usage) section, copy all of the contents in the provided example and place it within your newly created `lab1/main.tf` file.
   1. Once done, your main.tf should look like the following:

      ```bash
      resource "azurerm_resource_group" "example" {
        name     = "example-resources"
        location = "West Europe"
      }

      resource "azurerm_kubernetes_cluster" "example" {
        name                = "example-aks1"
        location            = azurerm_resource_group.example.location
        resource_group_name = azurerm_resource_group.example.name
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
          Environment = "Production"
        }
      }

      output "client_certificate" {
        value     = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
        sensitive = true    # When marked true, Terraform will automatically prevent the value from being exposed through plan/apply/output commands
      }

      output "kube_config" {
        value = azurerm_kubernetes_cluster.example.kube_config_raw

        sensitive = true
      }
      ```

1. Note the various `types` present in the example:
   1. [`resource`](https://www.terraform.io/language/v1.1.x/resources) - Resources are the most important element in the Terraform language. Each resource block describes one or more infrastructure objects, such as virtual networks, compute instances, or higher-level components such as DNS records.
   2. [`outputs`](https://www.terraform.io/language/v1.1.x/values) - Output Values are like return values for a Terraform module.

1. Customize your Resource Group Terraform resource:
   1. In the Terraform declaration: `resource "azurerm_resource_group" "example"`
         - Change the `"example"` to `"this"`. This is the Terraform resource object name, and is used to access the values for said resource, as well as create implicit dependencies across Terraform resources.
           - More about output values can be found in HashiCorp's documentation around [Output Values](https://www.terraform.io/language/values/outputs).
   2. In the resource group arguments (`name` and `location`):
         - Change the value for `name` from `example-resources` to a resource group name you would like to use for this deployment. For this lab, I will be using the name `aks-tf-labs-01`
         - Update the `location` to the [Azure geography](https://azure.microsoft.com/en-us/global-infrastructure/geographies/#geographies) that best suits you. For this lab, I will be using `Central US`.
   3. After following these steps, your resource group block should look like the following:

      ```hcl
      resource "azurerm_resource_group" "this" {
        name     = "aks-tf-labs-01"
        location = "Central US"
      }
      ```

2. Customize your Kubernetes Cluster Terraform resource:
      1. In the terraform declaration: `resource "azurerm_kubernetes_cluster" "example"`
         - repeat what you did for the resource group, and rename the `"example"` to `"this"`
      2. Give a name for your AKS cluster for the `"name"` argument. For this lab, I will be using `lab01-demo-cluster`.
      3. Update the resource group attributes to point to the new name we gave in the previous step for the resource group from `azurerm_resource_group.**example**` to `azurerm_resource_group.**this**`
      4. Remove the `dns_prefix` argument, as this is an [Optional argument](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#dns_prefix) for this deployment.
      5. Update the `tags` mapping to:
        ```hcl
          tags = {
            Environment = "dev" // Or whichever environment naming convention you would like to use for sandboxing/development
            Automation = "Terraform"
            Owner = "resourceOwner@myCompany.com"
          }
        ```
      6. Completing this step, your `azurerm_kubernetes_cluster` resource block should look like the following:

      ```hcl
        resource "azurerm_kubernetes_cluster" "this" {
          name                = "lab01-demo-cluster"
          location            = azurerm_resource_group.this.location
          resource_group_name = azurerm_resource_group.this.name
          # dns_prefix          = "exampleaks1" // This line should be missing or commented like shown here.

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
      ```

3. Configure your outputs:
   1. For the two output blocks that were copied over, `client_certificate` and `kube_config`, note the `value` for each references the `azurerm_kubernetes_cluster.example` resource.
      1. As we updated the `azurerm_resource_group.example` references from within the `azurerm_kubernetes_cluster.this` resource's `location` and `resource_group_name` arguments, the `value` must also be updated for the Terraform name change.

        ```hcl
          output "client_certificate" {
            value     = azurerm_kubernetes_cluster.this.kube_config.0.client_certificate
            sensitive = true
          }

          output "kube_config" {
            value = azurerm_kubernetes_cluster.this.kube_config_raw
            sensitive = true
          }
        ```

   1. Add a new `output` block and name it "`id`"

      ```hcl
        output "id" {}
      ```

   1. Specify a `description` for the output object

      ```hcl
        output "id" {
          description = "The Kubernetes Managed Cluster ID."
        }
      ```

   1. Map the attribute (output) of the AKS Terraform resource to the output block's `value` by referencing the [Terraform Resource Attribute Documentation for AKS](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#attributes-reference)

      ```hcl
        output "id" {
          description = "The Kubernetes Managed Cluster ID."
          value = azurerm_kubernetes_cluster.this.id
        }
      ```

## Section 4 - Deploy Terraform Configuration to Azure

-----

Now that you have the base components ready to go, all that is left is to deploy the configuration into your Azure subscription.

1. Within your Terraform project directory (same directory as where the `main.tf` is located), initialize the Terraform deployment by running `terraform init`

    ```hcl
    terraform init
    ```

   1. The `terraform init` command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.
   2. If you did the optional module on [Section 2.3](#section-2---configure-your-terraform-azure-provider) for remote state, if you see any `Unauthorized` errors, this is most likely due to invalid Azure credentials or limited network access to the target backend Azure storage account.
  
2. Run `terraform plan` to generate a deployment plan based on your Terraform configuration files.

    ```hcl
    terraform plan
    ```

   1. The `terraform plan` command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure. By default, when Terraform creates a plan it:
      - Reads the current state of any already-existing remote objects to make sure that the Terraform state is up-to-date.
      - Compares the current configuration to the prior state and noting any differences.
      - Proposes a set of change actions that should, if applied, make the remote objects match the configuration.

3. Run `terraform apply` to deploy your configuration, and when prompted, review the configuration plan and provide `yes` if the configuration looks good.

    ```hcl
    terraform apply
    ```

     1. When you run `terraform apply` without passing a saved plan file, Terraform automatically creates a new execution plan as if you had run terraform plan, prompts you to approve that plan, and takes the indicated actions. You can use all of the planning modes and planning options to customize how Terraform will create the plan.
     2. You can pass the -auto-approve option to instruct Terraform to apply the plan without asking for confirmation.

## Additional Documentation Relevant to this Lab

---

- Terraform Commands
  - [init](https://www.terraform.io/cli/commands/init)
  - [plan](https://www.terraform.io/cli/commands/plan)
  - [apply](https://www.terraform.io/cli/commands/apply)
- Terraform Concepts
  - [state file](https://www.terraform.io/language/state)
  - [store remote state in Azure Storage Accounts](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)
  - [writing/modifying tf code](https://www.terraform.io/cli/code)
- Terraform Object Types
  - [Resources](https://www.terraform.io/language/resources)
  - [Data Sources](https://www.terraform.io/language/data-sources)
  - [Providers](https://www.terraform.io/language/providers)

## Next Steps

---

And that is it for this lab! You can reference the [main deployment files](src) within this Lab's `src` directory to check your configuration.

- [main.tf](./src/main.tf)
- [version.tf](./src/version.tf)
