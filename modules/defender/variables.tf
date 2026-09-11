variable "plans" {
  description = "Defender for Cloud resource types to enable at Standard tier."
  type        = list(string)
  default = [
    "VirtualMachines",
    "StorageAccounts",
    "KeyVaults",
    "Containers",
    "OpenSourceRelationalDatabases",
    "CosmosDbs",
    "Arm",
  ]
}
