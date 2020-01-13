/*
.Synopsis
   Terraform Main Control
.DESCRIPTION
   This file holds the main control and resoures for the iac-terraform micro-svc-small application.
*/

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}

#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "name" {
  description = "An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "location" {
  description = "The Azure region where all resources in this template should be created."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 8
}

variable "web_apps" {
  description = "Metadata about apps to deploy, such as image metadata."
  type = list(object({
    app_name                 = string
    image_name               = string
    image_release_tag_prefix = string
  }))
}

variable "function_apps" {
  description = "Metadata about the function apps to be created."
  type = map(object({
    image = string
  }))
  default = {}
}

variable "docker_registry_server_url" {
  description = "The url of the container registry that will be utilized to pull container into the Web Apps for containers"
  type        = string
  default     = "docker.io"
}

variable "app_service_settings" {
  description = "Map of app settings that will be applied across all provisioned app services."
  type        = map(string)
  default     = {}
}

variable "scaling_rules" {
  description = "The scaling rules for the app service plan. Schema defined here: https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html#rule. Note, the appropriate resource ID will be auto-inflated by the template"
  type = list(object({
    metric_trigger = object({
      metric_name      = string
      time_grain       = string
      statistic        = string
      time_window      = string
      time_aggregation = string
      operator         = string
      threshold        = number
    })
    scale_action = object({
      direction = string
      type      = string
      cooldown  = string
      value     = number
    })
  }))
  default = [
    {
      metric_trigger = {
        metric_name      = "CpuPercentage"
        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"
        operator         = "GreaterThan"
        threshold        = 70
      }
      scale_action = {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT10M"
      }
      }, {
      metric_trigger = {
        metric_name      = "CpuPercentage"
        time_grain       = "PT1M"
        statistic        = "Average"
        time_window      = "PT5M"
        time_aggregation = "Average"
        operator         = "GreaterThan"
        threshold        = 25
      }
      scale_action = {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
  ]
}

variable "service_plan_size" {
  description = "The size of the service plan instance. Valid values are I1, I2, I3. See more here: . Details can be found at https://azure.microsoft.com/en-us/pricing/details/app-service/windows/"
  type        = string
  default     = "S1"
}

variable "service_plan_tier" {
   description = "The tier under which the service plan is created. Details can be found at https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans"
  type        = string
  default     = "Standard"
}

variable "cosmosdb_container_name" {
  description = "The cosmosdb container name."
  type        = string
  default     = "example"
}

variable "lock" {
  description = "Should the resource group be locked"
  default     = true
}



#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  // Sanitized Names
  app_id    = random_string.workspace_scope.keepers.app_id
  location  = replace(trimspace(lower(var.location)), "_", "-")
  ws_name   = random_string.workspace_scope.keepers.ws_name
  suffix    = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base name for resources, name constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.app_id) > 0 ? "${local.ws_name}${local.suffix}-${local.app_id}" : "${local.ws_name}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  tenant_id = data.azurerm_client_config.current.tenant_id

  // Resolved resource names
  name                  = local.base_name
  insights_name         = "${local.base_name_83}-ai"
  keyvault_name         = "${local.base_name_21}-kv"
  cosmosdb_account_name = "${local.base_name_83}-db"
  cosmosdb_database_name = "${local.base_name_83}"
  storage_name          = "${replace(local.base_name_21, "-", "")}" 
  service_plan_name     = "${local.base_name_83}-sp"
  app_service_name      = local.base_name_21
  func_app_name         = local.base_name_21
  ad_app_name           = "${local.base_name}-easyauth"
  ad_principal_name     = "${local.base_name}-principal"
  

  // Resolved TF Vars
  reg_url = var.docker_registry_server_url
  app_services = {
    for target in var.web_apps :
    target.app_name => {
      image = "${target.image_name}:${target.image_release_tag_prefix}"
    }
  }
}

#-------------------------------
# Application Resources  (common.tf)
#-------------------------------
resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "_", "-")
    app_id  = replace(trimspace(lower(var.name)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}


#-------------------------------
# Azure Required Providers
#-------------------------------
module "provider" {
  source = "../../modules/provider"
}


#-------------------------------
# Resource Group
#-------------------------------
module "resource_group" {
  # Module Path
  source = "github.com/danielscholl/iac-terraform/modules/resource-group"

  # Module variable
  name     = local.name
  location = local.location

  resource_tags = {
    environment = local.ws_name
  }
  isLocked = var.lock
}


#-------------------------------
# Application Insights
#-------------------------------
module "app_insights" {
  # Module Path
  source              = "github.com/danielscholl/iac-terraform/modules/app-insights"

  # Module variable
  name                = local.insights_name
  resource_group_name = module.resource_group.name
  type                = "Web"

  resource_tags = {
    environment = local.ws_name
  }
}

#-------------------------------
# Cosmos Database
#-------------------------------
module "cosmosdb" {
  # Module Path
  source = "github.com/danielscholl/iac-terraform/modules/cosmosdb"

  # Module variable
  name                     = local.cosmosdb_account_name
  resource_group_name      = module.resource_group.name
  kind                     = "GlobalDocumentDB"
  automatic_failover       = false
  consistency_level        = "Session"
  primary_replica_location = local.location
  database_name            = local.cosmosdb_database_name
  container_name           = var.cosmosdb_container_name

  resource_tags          = {
    environment = local.ws_name
  }
}

#-------------------------------
# Azure Key Vault
#-------------------------------
module "keyvault" {
  # Module Path
  source = "github.com/danielscholl/iac-terraform/modules/keyvault"

  # Module variable
  name           = local.keyvault_name
  resource_group_name = module.resource_group.name

  secrets              = {
    "cosmosdbName"        = module.cosmosdb.name
    "cosmosdbAccount"         = module.cosmosdb.endpoint
    "cosmosdbKey"             = module.cosmosdb.primary_master_key
  }

  resource_tags          = {
    environment = local.ws_name
  }
}

module "web_keyvault_policy" {
  source                  = "github.com/danielscholl/iac-terraform/modules/keyvault-policy"
  vault_id                = module.keyvault.id
  tenant_id               = module.app_service.identity_tenant_id
  object_ids              = module.app_service.identity_object_ids
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list"]
}

module "func_keyvault_policy" {
  source                  = "github.com/danielscholl/iac-terraform/modules/keyvault-policy"
  vault_id                = module.keyvault.id
  tenant_id               = module.function_app.identity_tenant_id
  object_ids              = module.function_app.identity_object_ids
  key_permissions         = ["get", "list"]
  secret_permissions      = ["get", "list"]
  certificate_permissions = ["get", "list"]
}


#-------------------------------
# Storage Account
#-------------------------------

module "storage_account" {
  source                    = "github.com/danielscholl/iac-terraform/modules/storage-account"
  resource_group_name       = module.resource_group.name
  name                      = substr(local.storage_name, 0, 23)
  containers = [
    {
      name  = "function-releases",
      access_type = "private"
    }
  ]
  encryption_source         = "Microsoft.Storage"
}


#-------------------------------
# Web Site
#-------------------------------
module "service_plan" {
  # Module Path
  source = "github.com/danielscholl/iac-terraform/modules/service-plan"

  # Module Variables
  name                = local.service_plan_name
  resource_group_name = module.resource_group.name
  size                = var.service_plan_size
  tier                = var.service_plan_tier
  scaling_rules       = var.scaling_rules


  resource_tags          = {
    environment = local.ws_name
  }
}

module "app_service" {
  # Module Path
  source = "github.com/danielscholl/iac-terraform/modules/app-service"

  # Module Variables
  name                       = local.app_service_name
  resource_group_name        = module.resource_group.name
  service_plan_name          = module.service_plan.name
  instrumentation_key        = module.app_insights.instrumentation_key

  app_service_config         = local.app_services
  docker_registry_server_url = local.reg_url
  app_settings               = {
    cosmosdb_database        = module.cosmosdb.name
    cosmosdb_account         = module.cosmosdb.endpoint
    cosmosdb_key             = module.cosmosdb.primary_master_key
  }
  secure_app_settings        = module.keyvault.references
  
  resource_tags          = {
    environment = local.ws_name
  }
}

module "function_app" {
  source = "github.com/danielscholl/iac-terraform/modules/function-app"
  name                    = local.func_app_name
  resource_group_name     = module.resource_group.name
  service_plan_name       = module.service_plan.name
  instrumentation_key     = module.app_insights.instrumentation_key
  storage_account_name    = module.storage_account.name

  app_settings               = var.app_service_settings
  # secure_app_settings        = module.keyvault.references
  
  is_java = true

  function_app_config = {
     func1 = {
        image = "danielscholl/spring-function-app:latest"
     }
  }

  resource_tags          = {
    environment = local.ws_name
  }
}

#-------------------------------
# Service Principal with Role Assignments
#-------------------------------
module "service_principal" {
  source = "github.com/danielscholl/iac-terraform/modules/service-principal"

  name = local.ad_principal_name
  role = "Contributor"
  scopes = concat(
    # Scope in App Services and Slots for deployments.
    module.app_service.ids,
    [
      # Scope in App Service Plan for management and scaling.
      module.service_plan.id
    ]
  )
}


#-------------------------------
# Easy Auth Configuration
#-------------------------------
module "ad_application" {
    source = "github.com/danielscholl/iac-terraform/modules/ad-application"

    name = local.ad_app_name
    reply_urls = flatten([
      for config in module.app_service.config_data :
      [
        format("https://%s", config.app_fqdn),
        format("https://%s/.auth/login/aad/callback", config.app_fqdn),
        format("https://%s", config.slot_fqdn),
        format("https://%s/.auth/login/aad/callback", config.slot_fqdn)
      ]
    ])
    required_resource_access = [
      {
        resource_app_id = "00000002-0000-0000-c000-000000000000" // ID for Windows Graph API
        resource_access = [
          {
            id = "824c81eb-e3f8-4ee6-8f6d-de7f50d565b7", // ID for Application.ReadWrite.OwnedBy
            type = "Role"
          }
        ]
      }
    ]
}

resource "null_resource" "auth" {
  count      = length(module.app_service.uris)
  depends_on = [module.ad_application.app_id]

  triggers = {
    app_service = join(",", module.app_service.uris)
  }

  provisioner "local-exec" {
    command = <<EOF
      az webapp auth update                     \
        --subscription "$SUBSCRIPTION_ID"       \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$APPNAME"                       \
        --enabled true                          \
        --action LoginWithAzureActiveDirectory  \
        --aad-token-issuer-url "$ISSUER"        \
        --aad-client-id "$APPID"                \
      && az webapp auth update                  \
        --subscription "$SUBSCRIPTION_ID"       \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$APPNAME"                       \
        --slot "$SLOTSHORTNAME"                 \
        --enabled true                          \
        --action LoginWithAzureActiveDirectory  \
        --aad-token-issuer-url "$ISSUER"        \
        --aad-client-id "$APPID"
      EOF

    environment = {
      SUBSCRIPTION_ID = data.azurerm_client_config.current.subscription_id
      RESOURCE_GROUP_NAME = module.resource_group.name
      SLOTSHORTNAME = "staging"
      APPNAME = module.app_service.config_data[count.index].app_name
      ISSUER = format("https://sts.windows.net/%s", local.tenant_id)
      APPID = module.ad_application.app_id
    }
  }
}