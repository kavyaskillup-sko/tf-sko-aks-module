# Security

This document maps the requested security enhancements to what is implemented, plus additional
OWASP-aligned hardening and residual risks/operator actions required.

## Implemented controls

### Network isolation
- No database, cache, registry, or vault has a public endpoint: MySQL is VNet-injected;
  Cosmos DB, Redis, Key Vault, ACR, and Storage use private endpoints with `public_network_access_enabled = false`.
- AKS API server is private (`private_cluster_enabled = true`) by default; the optional
  `authorized_ip_ranges` path is only used when explicitly opted out of a private cluster, and
  must never include `0.0.0.0/0`.
- All workload subnets force default-route egress through Azure Firewall (UDR); no NAT gateway or
  direct internet egress path exists on those subnets.
- NSGs apply explicit least-privilege allow rules per subnet plus an explicit deny-all inbound
  rule; nothing in this codebase authorizes `*`/`0.0.0.0/0` inbound.

### Firewall (egress allow-listing)
- Azure Firewall Policy default-denies; only explicitly listed FQDNs/ports (DNS, NTP, Microsoft
  services, package mirrors required by Open edX/Tutor) are allowed. Extend
  `application_rules`/`network_rules` in [network.tf](../network.tf) rather than widening scope.
- Threat Intelligence mode is `Alert` in dev/uat and `Deny` in prod (`local.is_prod`); Premium SKU
  in prod also enables IDPS (`intrusion_detection` in `Deny` mode) for signature-based threat
  blocking on both ingress and egress firewall traffic.
- NSG flow logs (v2) with Traffic Analytics are enabled for the `aks`/`data`/`mysql` NSGs
  (`enable_nsg_flow_logs`), giving network-level forensics beyond NSG rule-hit counters.

### Identity & secrets
- Managed identities (user-assigned) are used for AKS control plane, kubelet (ACR pull), and pod
  workload identity — no client secrets or SP passwords are provisioned.
- Key Vault uses **RBAC authorization** (not access policies), soft-delete + purge protection,
  and is reachable only via private endpoint.
- The one unavoidable static credential (MySQL admin password) is generated with
  `random_password` (32 chars, mixed classes) and written straight to Key Vault; it is never
  passed as a plain `tfvars` value and is marked `sensitive` in outputs.
- ACR admin user is disabled; image pulls use the kubelet identity + `AcrPull` RBAC role.
- Storage account has `shared_access_key_enabled = false` — access is via Azure AD/RBAC only.

### Encryption
- All data services enforce TLS in transit: MySQL (`require_secure_transport=ON`, TLS 1.2),
  Redis (`minimum_tls_version=1.2`, non-SSL port disabled), Storage (`min_tls_version=TLS1_2`),
  Cosmos DB (HTTPS only), Key Vault (HTTPS only).
- Encryption at rest uses a **customer-managed key (CMK)** by default (`enable_customer_managed_keys`):
  the `keyvault` module provisions an RSA-3072 key with an automatic 1-year rotation policy, plus a
  Disk Encryption Set for any standalone managed disks. Storage and MySQL Flexible Server wrap their
  encryption with this key via their own managed identities; Cosmos DB wraps it via Azure's
  first-party Cosmos DB service principal. Disable via `enable_customer_managed_keys = false` to fall
  back to platform-managed keys (e.g. for lower environments where key-management overhead isn't
  justified — see `envs/dev/terraform.tfvars`).
- Redis (standard Premium tier) has no CMK support in Terraform; only Redis Enterprise does. Not
  implemented here since it would require switching tiers/resource types.

### Auditing / monitoring
- A dedicated Log Analytics workspace collects diagnostic logs from every resource type deployed
  (see [ARCHITECTURE.md](ARCHITECTURE.md#observability)) with configurable retention
  (`log_retention_days`, default 90, 180 in prod tfvars).
- The subscription **Activity Log** is also shipped to the same workspace
  ([activity-log.tf](../activity-log.tf)), covering Administrative, Security, ServiceHealth, Alert,
  Recommendation, Policy, Autoscale, and ResourceHealth categories — full control-plane audit trail,
  not just data-plane/resource logs.
- AKS: `kube-audit`, `kube-apiserver`, `kube-controller-manager`, and `guard` (AAD auth) logs are
  enabled; Microsoft Defender for Containers is enabled via `microsoft_defender`.
- Optional **Microsoft Defender for Cloud** plans (`enable_defender_for_cloud`) for VMs, Storage,
  Key Vault, Containers, Cosmos DB, MySQL, and Azure Resource Manager — subscription-wide, so only
  enable it in one environment stack (see [modules/defender](../modules/defender)).
- Key Vault `AuditEvent` logs and ACR login/repository events are captured for access forensics.

### Availability / resilience
- AKS system + user node pools span 3 availability zones with autoscaling.
- MySQL, Redis (Premium), and Cosmos DB support zone redundancy; MySQL HA uses a zone-redundant
  standby; Cosmos DB supports multi-region failover via `cosmosdb_failover_locations`.
- Storage uses ZRS (dev/uat) or GZRS (prod) replication.

### Tagging
- Every resource inherits `local.tags` = mandatory tags (`Environment`, `Project`, `Owner`,
  `CostCenter`, `ManagedBy`, `DataSensitivity`) merged with any environment-specific `var.tags`.

## Operator responsibilities (not automated here)

1. **Populate `aks_admin_group_object_ids`** with real Azure AD group object IDs before granting cluster-admin — the default is an empty list (no
   admins) to fail closed.
2. **Set `enable_defender_for_cloud = true`** in exactly one environment stack per subscription
   (it's a subscription-wide setting) for full CSPM/vulnerability scanning coverage.
3. **Review and tighten firewall FQDN allow-lists** for your actual Tutor/Open edX plugin set
   before go-live; the shipped list is a reasonable starting point, not exhaustive.
4. **Rotate the MySQL admin password** stored in Key Vault periodically (e.g. via a scheduled
   Automation runbook) since Terraform will not proactively rotate `random_password` on every
   apply (it's stable across applies by design).
5. **Run `terraform apply` from a network location with Key Vault data-plane access** (VNet,
   VPN, or an allow-listed IP) when `enable_customer_managed_keys` or secrets are involved —
   the vault has `public_network_access_enabled = false`, so a GitHub-hosted runner on the public
   internet cannot write the CMK/secrets unless temporarily allow-listed or run via a
   self-hosted runner inside the VNet.
6. Consider a **DDoS Network Protection plan** (`enable_ddos_protection = true`, already wired) for
   internet-facing production VNets.

## OWASP Top 10 mapping (infrastructure-relevant subset)

| OWASP concern | Mitigation in this repo |
|---|---|
| Broken access control | RBAC-only Key Vault/Storage, Azure AD RBAC on AKS, least-privilege NSGs |
| Cryptographic failures | TLS 1.2+ everywhere, encryption at rest by default, secrets never in state as plain vars |
| Injection / SSRF via egress | Firewall default-deny egress with FQDN allow-listing |
| Insecure design | Private-by-default modules — public access must be explicitly re-enabled to break it |
| Security misconfiguration | Deny-all NSG fallback rule, `network_acls`/`network_rules` default deny on Key Vault/ACR/Storage |
| Vulnerable components | AKS `automatic_channel_upgrade = "patch"`, ACR image quarantine, image cleaner enabled |
| Identification/auth failures | Managed identities + Azure AD RBAC instead of static credentials |
| Security logging/monitoring failures | Central Log Analytics workspace + diagnostic settings on every resource |
