# ---------------------------
# Azure Key Vault
# ---------------------------
variable "tenant_id" {
  default = ""
}

variable "key_name" {
  description = "Azure Key Vault key name"
  default     = "generated-key"
}

variable "location" {
  description = "Azure location where the Key Vault resource to be created"
  default     = "northeurope"
}

variable "environment" {
  default = "learn-hashi"
}

# ---------------------------
# Virtual Machine
# ---------------------------
variable "public_key" {
  default = ""
}

variable "subscription_id" {
  default = ""
}

variable "vm_name" {
  default = "azure-auth-demo-vm"
}

variable "vault_version" {
  # NB execute `apt-cache madison vault` to known the available versions.
  default = "1.5.5"
}

# variable "resource_group_name" {
#   default = "vault-demo2-azure-auth"
# }

variable "key_vault_name" {
  default = "akv-learn-vault"
}