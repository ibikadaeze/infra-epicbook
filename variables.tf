variable "resource_group_name" {
  default = "epicbook-dev-rg"
}

variable "prefix" {
  description = "Prefix used for Azure resource names."
  type        = string
  default     = "epicbook-dev"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "Canada Central"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to your SSH Public Key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network."
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR range allowed to SSH into the VM."
  type        = string
  default     = "*"
}

variable "db_subnet_cidr" {
  description = "CIDR block for the database subnet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "db_server_name" {
  description = "Azure MySQL Flexible Server name"
  default     = "epicbook-dev-mysql"
}

variable "db_name" {
  description = "Application database name"
  default     = "epicbook"
}

variable "db_admin_username" {
  description = "MySQL administrator username"
  default     = "epicbookadmin"
}

variable "db_admin_password" {
  description = "MySQL administrator password"
  type        = string
  sensitive   = true
}


variable "db_sku" {
  description = "SKU for MySQL Flexible Server (e.g., B_Standard_B1s, B_Standard_B2s)."
  type        = string
  default     = "B_Standard_B1s"
}

variable "db_storage_gb" {
  description = "Storage size for MySQL database in GB."
  type        = number
  default     = 20
}


variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
