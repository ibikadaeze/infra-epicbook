resource_group_name = "epicbook-dev-rg"
prefix              = "epicbook-dev"
environment         = "dev"
location            = "Canada Central"
vm_size             = "Standard_D2s_v3"
admin_username      = "azureuser"
allowed_ssh_cidr    = "0.0.0.0/0"
db_admin_password   = "Peculiar1234!"

tags = {
  owner   = "adaeze"
  project = "epicbook"
}
