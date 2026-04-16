
output "app_vm_name" {
  description = "EpicBook frontend VM name."
  value       = azurerm_linux_virtual_machine.vms["app"].name
}

output "app_public_ip" {
  description = "EpicBook frontend VM public IP address."
  value       = azurerm_public_ip.vms["app"].ip_address
}

output "mysql_fqdn" {
  description = "EpicBook MySQL flexible server FQDN."
  value       = azurerm_mysql_flexible_server.db.fqdn
}

output "mysql_database_name" {
  description = "EpicBook MySQL database name."
  value       = azurerm_mysql_flexible_database.app.name
}

output "mysql_admin_username" {
  description = "EpicBook MySQL administrator username."
  value       = azurerm_mysql_flexible_server.db.administrator_login
}
