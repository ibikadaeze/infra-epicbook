locals {
  name = var.prefix
  tags = merge(
    {
      project     = "epicbook"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.tags
  )
  vm_types = ["app"]
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${local.name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidr]
}

# Database Subnet
resource "azurerm_subnet" "database" {
  name                 = "${local.name}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "vms" {
  name                = "${local.name}-vms-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-backend-api"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "database" {
  name                = "${local.name}-db-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "allow-mysql"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "${local.name}.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${local.name}-mysql-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.tags
}

# Public IPs for VMs
resource "azurerm_public_ip" "vms" {
  for_each            = toset(local.vm_types)
  name                = "${local.name}-${each.value}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(local.tags, { vm_type = each.value })
}

# Network Interfaces for VMs
resource "azurerm_network_interface" "vms" {
  for_each            = toset(local.vm_types)
  name                = "${local.name}-${each.value}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(local.tags, { vm_type = each.value })

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vms[each.value].id
  }
}

# Associate NSGs with Network Interfaces
resource "azurerm_network_interface_security_group_association" "vms" {
  for_each                  = toset(local.vm_types)
  network_interface_id      = azurerm_network_interface.vms[each.value].id
  network_security_group_id = azurerm_network_security_group.vms.id
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "vms" {
  for_each            = toset(local.vm_types)
  name                = "${local.name}-${each.value}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vms[each.value].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(local.tags, { vm_type = each.value })
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "db" {
  name                         = var.db_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  administrator_login          = var.db_admin_username
  administrator_password       = var.db_admin_password
  backup_retention_days        = 7
  delegated_subnet_id          = azurerm_subnet.database.id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql.id
  geo_redundant_backup_enabled = false
  sku_name                     = "B_Standard_B1ms"
  version                      = "8.0.21"
  zone                         = "1"

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql,
  ]
}

resource "azurerm_mysql_flexible_database" "app" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.db.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
