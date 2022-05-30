# ---------------------------
# Azure Key Vault
# ---------------------------
variable "tenant_id" {
  default = "72f988bf-86f1-41af-91ab-2d7cd011db47"
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
  default = "learn-hashivault"
}

# ---------------------------
# Virtual Machine
# ---------------------------
variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6vb2biWtl8N1M+Aiay98aXZC7yXGH3zH3Stm9eH+h4ma+ii0KiY8waHRJl2n1TalSJFw61+Ys1/dEp/wVgTJUgUh7C7omGQyaA7d38O2tR32heKvUXvkEbx+VoPBBRSJKZDtKJ4jQopwkJxj+CKTsPHD/21GDI4xaxVPOyfdI11sUj3ik4l3IrC+cSdGqLu7VHPL4ff9zwKzHKUKFuPrpXs0HhIiqVW6TiHQ+xm3v+eb5lsxbHtO+xcOB6Wgjyk5Nv1RGngQ4aeHQ/mOviB+MBE5J7qunYW7waLrqOeMDN8RX3Fde1bZm6kS2s9iG0jwzzD722TAaD66Igehukx7pV9kD7oVE0moWnvlD6EuEcMg6kP4UB4yk/cjbzuagHoDDWUlx4ePgZMZbosPAzB+qhFbUFVGvZaxnNF0Ov+PgkG8Sq2ybk5Y4X92vznlHi1ut1jbYMps163AsrkjVU6DqtIQcEghpvbxpjreoa3ItEYDTA76ulaH1bUgIS7h/IWk= azureuser"
}

variable "subscription_id" {
  default = "779b3f2b-726d-430d-a1b7-f8c309b3bbd0"
}

variable "vm_name" {
  default = "hashi-vault-demo-vm"
}

variable "vault_version" {
  # NB execute `apt-cache madison vault` to known the available versions.
  default = "1.5.5"
}


variable "key_vault_name" {
  default = "akv-hashi-vault"
}