##############################################################
# This module allows the creation of a PostgreSQL server and database
##############################################################

variable "resource_group_name" {
  description = "The Resource group to contain the PostgreSQL database/server "
  type        = string
}

variable "postgresql_server_name" {
  description = "The PostgreSQL server name"
  type        = string
}

variable "postgresql_database_name" {
  description = "The PostgreSQL database name"
  type        = string
  default     = "airflow"
}



variable "postgresql_login" {
  description = "The PostgreSQL server login name"
  type        = string
}

variable "postgresql_password" {
  description = "The PostgreSQL server login password"
  type        = string
}

variable "postgresql_server_sku" {
  description = "The PostgreSQL sku"
  type        = string
  default     = "B_Gen5_2"    
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}