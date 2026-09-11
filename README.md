# Terraform AKS Module

A Terraform module for provisioning and managing an Azure Kubernetes Service (AKS) cluster.

## Status

This repository is currently being initialized. Module resources, variables, outputs, and examples will be added as the implementation evolves.

## Prerequisites

- Terraform >= 1.5
- An Azure subscription
- Azure CLI authenticated with an account that can create AKS and related Azure resources
- Appropriate permissions for the target resource group and networking resources

## Planned Usage

The module will be consumed from a Terraform root module after its implementation is available:

```hcl
module "aks" {
  source = "./modules/aks"

  # Configure module inputs here.
}
```

## Development

Format and validate Terraform code before opening a change:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

## Contributing

Please keep changes focused, document new inputs and outputs, and include or update examples when module behavior changes.
