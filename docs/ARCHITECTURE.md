# Architecture

## Overview

This Terraform codebase provisions a single-region (with optional cross-region backup/failover)
Azure landing zone for Open edX, structured as a hub-lite spoke: one VNet contains a dedicated
`AzureFirewallSubnet` alongside workload subnets, with all egress from workload subnets forced
through Azure Firewall via user-defined routes (UDRs).

## Subnets

| Subnet     | Purpose                                              | Internet-facing? |
|------------|-------------------------------------------------------|-------------------|
| `aks`      | AKS nodes (private cluster, Azure CNI overlay)         | No (UDR → Firewall) |
| `data`     | Private endpoints: Key Vault, ACR, Redis, Cosmos DB, Storage | No |
| `mysql`    | Delegated subnet for MySQL Flexible Server VNet injection | No |
| `firewall` | `AzureFirewallSubnet` — Azure Firewall Standard/Premium | Firewall has one public IP for SNAT/DNAT only |

## Compute

- **AKS**: Private API server, Azure AD + Kubernetes RBAC, Azure CNI Overlay with Cilium network
  policy, system + user node pools spread across 3 availability zones, cluster autoscaler,
  ephemeral OS disks, Key Vault Secrets Provider (CSI) with auto-rotation, workload identity/OIDC
  federation for pod-level Azure AD auth, Azure Policy add-on, Microsoft Defender for Containers,
  image cleaner, weekly maintenance window for patch upgrades.
- **ACR**: Premium SKU (required for private endpoints and zone redundancy), public access
  disabled, pulled by AKS via the kubelet managed identity (`AcrPull` role) — no admin credentials.

## Data services

- **MySQL** (Azure Database for MySQL Flexible Server): VNet-injected (no private endpoint needed
  — the server itself lives inside the delegated subnet), zone-redundant HA in prod, TLS-enforced,
  automated geo-redundant backups, 35-day retention in prod.
- **Cosmos DB** (Mongo API): public network access disabled, private endpoint only, zone-redundant
  geo-replication, continuous backup (point-in-time restore).
- **Redis**: Premium SKU for private endpoint + zone redundancy support, TLS 1.2 minimum, non-SSL
  port disabled, RDB persistence optional.
- **Storage account**: Blob private endpoint only, versioning + soft delete, TLS 1.2 minimum,
  shared-key auth disabled (Azure AD/RBAC only), ZRS/GZRS replication.

## Networking security

- Azure Firewall Policy with explicit **allow-list** application/network rules (default deny);
  DNS proxy enabled for FQDN filtering of egress traffic.
- Per-subnet NSGs (module `nsg`) apply least-privilege inbound rules and an explicit deny-all
  inbound rule as defense in depth (Azure default security rules already deny, but this makes
  intent explicit and auditable).
- Route tables force 0.0.0.0/0 from every workload subnet to the firewall's private IP
  (forced tunneling) so no workload can reach the internet directly.
- Private DNS zones for `privatelink.*` are created once and linked to the VNet, so name
  resolution for all private-endpoint-backed services stays inside the network.

## Identity & access

- All service-to-service auth uses **user-assigned managed identities** — no client secrets,
  connection strings with embedded keys, or service principal passwords are created by this
  module (the one exception is the MySQL admin password, which is a requirement of the MySQL
  protocol; it is generated with `random_password` and stored only in Key Vault).
- AKS uses Azure AD for cluster authentication and Kubernetes RBAC / Azure RBAC for authorization;
  `local_account_disabled = true` removes the cluster's local admin credential entirely.
- Workload Identity (OIDC federation) lets in-cluster pods authenticate to Key Vault/Storage as
  the `workload` managed identity without any secret material inside the cluster.

## Observability

- Central Log Analytics workspace receives diagnostic logs from the VNet, NSGs, Firewall, Key
  Vault, ACR, AKS control plane (audit, apiserver, controller-manager, guard), MySQL (audit/slow
  query logs), Cosmos DB (data/control plane requests), Redis, and Storage (read/write/delete).
- Container Insights + Microsoft Defender for Containers are enabled on AKS.
