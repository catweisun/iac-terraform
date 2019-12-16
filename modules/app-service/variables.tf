variable "name" {
  description = "The name of the web app."
  type        = string
}

variable "resource_group_name" {
  description = "The name of an existing resource group."
  type        = string
}

variable "service_plan_name" {
  description = "The name of the service plan"
  type        = string
}

variable "uses_acr" {
  description = "Determines whether or not an Azure container registry is being used"
  type        = bool
  default     = false
}

variable "azure_container_registry_name" {
  description = "The name of the azure container registry resource"
  type        = string
  default     = ""
}

variable "resource_tags" {
  description = "Map of tags to apply to taggable resources in this module. By default the taggable resources are tagged with the name defined above and this map is merged in"
  type        = map(string)
  default     = {}
}

variable "app_settings" {
  type        = map(string)
  default     = {}
  description = "Map of App Settings."
}

variable "app_service_config" {
  description = "Metadata about the app services to be created."
  type = map(object({
    // If "", no container configuration will be set. Otherwise, this will be used to set the container configuration for the app service.
    image = string
  }))
  default = {}
}

variable "enable_storage" {
  description = "Determines whether or not a storage is attached to the app service."
  type        = bool
  default     = false
}

variable "vault_uri" {
  description = "Specifies the URI of the Key Vault resource. Providing this will create a new app setting called KEYVAULT_URI containing the uri value."
  type        = string
  default     = ""
}

variable "app_insights_instrumentation_key" {
  description = "The Instrumentation Key for the Application Insights component used for app service to be created"
  type        = string
  default     = ""
}

variable "site_config_always_on" {
  description = "Should the app be loaded at all times? Defaults to true."
  type        = string
  default     = true
}

variable "uses_vnet" {
  description = "Determines whether or not a virtual network is being used"
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "The vnet integration name."
  type        = string
  default     = ""
}

variable "vnet_subnet_id" {
  description = "The vnet integration subnet gateway identifier."
  type        = string
  default     = ""
}

variable "docker_registry_server_url" {
  description = "The docker registry server URL for app service to be created"
  type        = string
  default     = "docker.io"
}

variable "docker_registry_server_username" {
  description = "The docker registry server username for app service to be created"
  type        = string
  default     = ""
}

variable "docker_registry_server_password" {
  description = "The docker registry server password for app service to be created"
  type        = string
  default     = ""
}

variable "cosmosdb_name" {
  description = "The comsosdb account name"
  type        = string
  default     = ""
}


locals {
  access_restriction_description = "blocking public traffic to app service"
  access_restriction_name        = "vnet_restriction"
  acr_webhook_name               = "cdhook"
  app_names                      = keys(var.app_service_config)
  app_configs                    = values(var.app_service_config)

  docker_settings = var.docker_registry_server_url != "" ? {
    DOCKER_REGISTRY_SERVER_URL          = format("https://%s", var.docker_registry_server_url)
    DOCKER_REGISTRY_SERVER_USERNAME     = var.docker_registry_server_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = var.docker_registry_server_password
  } : {}

  cosmosdb_settings = var.cosmosdb_name != "" ? {
    cosmosdb_database                   = data.azurerm_cosmosdb_account.account.name
    cosmosdb_account                    = data.azurerm_cosmosdb_account.account.endpoint
    cosmosdb_key                        = data.azurerm_cosmosdb_account.account.primary_master_key
  } : {}

  app_settings = merge(
    var.app_settings,
    local.docker_settings,
    local.cosmosdb_settings,
    {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    },
  )


  app_linux_fx_versions = [
    for config in values(var.app_service_config) :
    // Without specifyin a `linux_fx_version` the webapp created by the `azurerm_app_service` resource
    // will be a non-container webapp.
    //
    // The value of "DOCKER" is a stand-in value that can be used to force the webapp created to be
    // container compatible without explicitly specifying the image that the app should run.
    config.image == "" ? "DOCKER" : format("DOCKER|%s/%s", var.docker_registry_server_url, config.image)
  ]
}
