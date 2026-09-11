# Deployment Guide

## 1. Prerequisites

- Terraform >= 1.7, Azure CLI, `az login` with Owner/Contributor + User Access Administrator
  (for role assignments) on the target subscription.
- Decide on Azure AD groups for AKS cluster-admin (`aks_admin_group_object_ids`) ahead of time.

## 2. Bootstrap remote state (once per environment)

Uses a Terraform workspace per environment so the same `bootstrap` state file can manage all
three state-storage accounts without name collisions:

```bash
cd bootstrap
terraform init

terraform workspace new dev
terraform apply -var-file=dev.tfvars

terraform workspace new uat
terraform apply -var-file=uat.tfvars

terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

Edit `allowed_ip_ranges` in `bootstrap/<env>.tfvars` before applying. Confirm the resulting
`storage_account_name`/`resource_group_name` outputs match `envs/<env>/backend.hcl`.

## 3. Initialize and plan an environment

```bash
cd ..
terraform init -backend-config=envs/dev/backend.hcl -reconfigure

terraform plan \
  -var-file=envs/dev/terraform.tfvars \
  -out=dev.plan
```

Review the plan carefully — in particular confirm:
- No resource has `public_network_access_enabled = true` unexpectedly.
- NSG rules do not contain `0.0.0.0/0` or `*` source prefixes.
- AKS `private_cluster_enabled` is `true`.

## 4. Apply

```bash
terraform apply dev.plan
```

Repeat for `uat` and `prod`, each with its own backend/tfvars and a fresh plan/approval cycle.
Use CI/CD (e.g. GitHub Actions/Azure DevOps with OIDC federation to Azure — no stored SP secrets)
for uat/prod applies, requiring manual approval gates for prod.

## 5. Post-deployment validation

```bash
# Confirm no public IPs exist except the Firewall
az network public-ip list -g <resource-group> -o table

# Confirm AKS API server is private
az aks show -g <resource-group> -n aks-openedx-<env>-<region> --query "apiServerAccessProfile"

# Confirm data services reject public access
az mysql flexible-server show -g <rg> -n mysql-openedx-<env>-<region> --query "network"
az redis show -g <rg> -n redis-openedx-<env>-<region> --query "publicNetworkAccess"
az cosmosdb show -g <rg> -n cosmos-openedx-<env>-<region> --query "publicNetworkAccess"
az keyvault show -n kv-openedx<env><region> --query "properties.publicNetworkAccess"

# Confirm diagnostic settings exist
az monitor diagnostic-settings list --resource <resource-id>
```

## 6. Connect kubectl (private cluster)

The AKS API server has no public endpoint. Connect via `az aks command invoke`, a self-hosted
runner/agent inside the VNet, or a private DNS-resolving VPN/ExpressRoute connection into the VNet:

```bash
az aks get-credentials -g <resource-group> -n aks-openedx-<env>-<region> --overwrite-existing
kubectl get nodes   # run this from inside the VNet, or via `az aks command invoke`
```

## 7. Destroy / teardown

```bash
terraform destroy -var-file=envs/dev/terraform.tfvars
```

Key Vault purge protection (enabled in prod) prevents immediate hard-deletion; plan decommission
timelines accordingly. The bootstrap state-storage account is not destroyed by this command — tear
it down separately and only after confirming no environment still references it.
