##############################################################
# This module allows the creation of a PostgreSQL server and database
##############################################################

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_postgresql_server" "main" {
  name                = var.postgresql_server_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  sku_name            = var.postgresql_server_sku

  storage_mb          = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = var.postgresql_login
  administrator_login_password = var.postgresql_password
  version                      = "9.5"
  ssl_enforcement_enabled      = true

  tags                         = var.resource_tags           
}


resource "azurerm_postgresql_database" "main" {
  name                = var.postgresql_database_name
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "enable_azure_service_access" {
  name                = "Azure"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_postgresql_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
