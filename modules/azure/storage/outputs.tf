output "data_storage_account_id" {
  description = "ID of the data storage account"
  value       = azurerm_storage_account.data.id
}

output "data_storage_account_name" {
  description = "Name of the data storage account"
  value       = azurerm_storage_account.data.name
}

output "logs_storage_account_id" {
  description = "ID of the logs storage account"
  value       = azurerm_storage_account.logs.id
}

output "logs_storage_account_name" {
  description = "Name of the logs storage account"
  value       = azurerm_storage_account.logs.name
}

output "data_container_name" {
  description = "Name of the data container"
  value       = azurerm_storage_container.data.name
}

output "logs_container_name" {
  description = "Name of the logs container"
  value       = azurerm_storage_container.logs.name
}

output "appgw_logs_container_name" {
  description = "Name of the Application Gateway logs container"
  value       = azurerm_storage_container.appgw_logs.name
}
