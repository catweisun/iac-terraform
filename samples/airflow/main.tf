/*
.Synopsis
   Terraform Main Control
.DESCRIPTION
   This file holds the main control and resoures for the iac-terraform simple cluster template.
*/

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}

#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  version = "=2.16.0"
  features {}
}

provider "null" {
  version = "~>2.1.0"
}

provider "random" {
  version = "~>2.2"
}

provider "local" {
  version = "1.4.0"
}

provider "azuread" {
  version = "=0.10.0"
}

provider "kubectl" {
  config_path = module.aks.kube_config_path
}

provider "helm" {
  kubernetes {
    config_path = module.aks.kube_config_path
  }
}
provider "kubernetes" {
    config_path = module.aks.kube_config_path
}


#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "output_directory" {
  type    = string
  default = "./output"
}

variable "kubeconfig_filename" {
  description = "Name of the kube config file saved to disk."
  type        = string
  default     = "bedrock_kube_config"
}

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

variable "agent_vm_count" {
  type    = string
  default = "2"
}

variable "agent_vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "client_id" {
  type    = string
}

variable "client_secret" {
  type    = string
}

variable "postgresqllogin" {
  type    = string
}

variable "postgresqlpwd" {
  type    = string
}

variable "airflow_username" {
  type    = string
}

variable "airflow_password" {
  type    = string
}
variable "osdu_az_principal_client_id" {
  type    = string
}
variable "osdu_az_principal_client_secret" {
  type    = string
}
variable "osdu_az_principal_resource" {
  type    = string
}
variable "osdu_az_principal_tenant_id" {
  type    = string
}

variable "environemtn_name" {
  type    = string
}

variable "dag_sync_key_file" {
  type   = string
}

variable "common_repository" {
  type   = string
}
variable "common_repository_username" {
  type  = string
}
variable "common_repository_password" {
  type  = string 
}
data "azurerm_client_config" "current" {}
#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  // Sanitized Names
  app_id   = random_string.workspace_scope.keepers.app_id
  location = replace(trimspace(lower(var.location)), "_", "-")
  ws_name  = random_string.workspace_scope.keepers.ws_name
  suffix   = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // Base Names
  base_name    = length(local.app_id) > 0 ? "${local.ws_name}${local.suffix}-${local.app_id}" : "${local.ws_name}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"

  // Resolved resource names
  name                                        = "${local.base_name}"
  stg_name                                    = "${replace(local.base_name, "-", "")}stg"
  vnet_name                                   = "${local.base_name}-vnet"
  cluster_name                                = "${local.base_name}-cluster"
  registry_name                               = "${replace(local.base_name_21, "-", "")}"
  keyvault_name                               = "${local.base_name_21}-kv"
  appinsights_name                            = "${local.base_name}-appinsights"
  ad_principal_name                           = "${local.base_name}-principal"
  postgresql_server                           = "${local.base_name}-airflowdb"
  redis_server                                = "${local.base_name}-redis"
  user_assigned_identity_name                 = "${local.base_name}-usi"
  user_assigned_identity_binding_name         = "${local.user_assigned_identity_name}-binding"
  tenant_id                                   = data.azurerm_client_config.current.tenant_id
  airflow_namespace                           = "airflow${var.environemtn_name}"
  airflow_instance_name                       = "${local.base_name}-airflow"
  kube_config_path                            = "${var.output_directory}/${var.kubeconfig_filename}"
  postgresql_login                            = "${var.postgresqllogin}@${local.postgresql_server}"
  # deployment manifest files
  auzre_identity_yaml                         = "${var.output_directory}/azure_identity.yaml"
  azure_identity_binding_yaml                 = "${var.output_directory}/azure_identity_binding.yaml"
  external_secret_values_yaml                 = "${var.output_directory}/external_secret_values.yaml"
  osdu_az_principal_yaml                      = "${var.output_directory}/osdu_az_principal.yaml"
  osdu_dag_sync_secret_yaml                   = "${var.output_directory}/osdu_dag_sync_secret.yaml"
  osdu_airflow_secret_yaml                    = "${var.output_directory}/osdu_airlfow_secret.yaml"
  configmap_airflow_remote_log_yaml           = "${var.output_directory}/configmap_airflow_remote_log_config.yaml"
  airflow_helm_values_yaml                    = "${var.output_directory}/airflow_helm_values_yaml.yaml"
  airflow_helm_local_chart_dir                = "${var.output_directory}/helm/charts"
  airflow_helm_local_chart                    = "${var.output_directory}/helm/charts/airflow"
  airflow_helm_chart                          = "${var.common_repository}/osdu/airflow:latest"
  appinsights_statsd_config_js                 = "${var.output_directory}/appinsights_statsd_config.js"
  # template files
  auzre_identity_template_yaml                = "./template/azure_identity_template.yaml"
  azure_identity_binding_template_yaml        = "./template/azure_identity_binding_template.yaml"
  external_secret_values_template_yaml        = "./template/external_secret_values_template.yaml"
  osdu_az_principal_template_yaml             = "./template/osdu_az_principal_template.yaml"
  osdu_dag_sync_secret_template_yaml          = "./template/osdu_dag_sync_secret_template.yaml"
  osdu_airflow_secret_template_yaml           = "./template/osdu_airflow_secret_template.yaml"
  configmap_airflow_remote_log_template_yaml  = "./template/configmap_airflow_remote_log_template.yaml"
  airflow_helm_values_template_yaml           = "./template/osud_airflow_helm_values_template.yaml"
  appinsights_statsd_config_template_js        = "./template/appinsights_statsd_config_template.js"
}


#-------------------------------
# Common Resources  (common.tf)
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


#-------------------------------
# SSH Key
#-------------------------------
resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "null_resource" "save-key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.key.private_key_pem}" > ${path.module}/.ssh/id_rsa
      chmod 0600 ${path.module}/.ssh/id_rsa
    EOF
  }
}


#-------------------------------
# Resource Group
#-------------------------------
module "resource_group" {
  source = "../../modules/resource-group"

  name     = local.name
  location = local.location

  resource_tags = {
    environment = local.ws_name
  }
}

#-------------------------------
# Storage Account
#-------------------------------
module "storage" {
  source = "../../modules/storage-account"

  name                = local.stg_name
  resource_group_name = module.resource_group.name
  containers          = [
    { 
      name = "airflow-logs"
      access_type = "private" 
      }
    ]

  resource_tags = {
    environment = local.ws_name
  }    
}


#-------------------------------
# Virtual Network
#-------------------------------
module "network" {
  source = "../../modules/network"

  name                = local.vnet_name
  resource_group_name = module.resource_group.name
  address_space       = "10.10.0.0/16"
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = ["10.10.0.0/17"]
  subnet_names        = ["Cluster-Subnet"]
}


#-------------------------------
# Container Registry
#-------------------------------
module "container_registry" {
  source = "../../modules/container-registry"

  name                = local.registry_name
  resource_group_name = module.resource_group.name

  is_admin_enabled = false
}


#-------------------------------
# Azure Key Vault
#-------------------------------
module "keyvault" {
  # Module Path
  source = "../../modules/keyvault"

  # Module variable
  name                = local.keyvault_name
  resource_group_name = module.resource_group.name

  resource_tags = {
    environment = local.ws_name
  }
}

data "local_file" "dag_sync_key_file" {
  filename = var.dag_sync_key_file
}

module "keyvault_secret" {
  # Module Path
  source = "../../modules/keyvault-secret"

  keyvault_id = module.keyvault.id
  secrets = {
    # "sshKey"       = tls_private_key.key.private_key_pem
    # "clientId"     = module.service_principal.client_id
    # "clientSecret" = module.service_principal.client_secret
    # "clientId"     = var.client_id
    # "clientSecret" = var.client_secret
    "airflow-connections-az-log" = format("wasb://%s:%s",local.stg_name,module.storage.primary_access_key)
    "airflow-redis-secret" = module.redis.primary_access_key
    "airflow-db-secret" = var.postgresqlpwd
    "osdu-az-principal-client-id" = var.osdu_az_principal_client_id
    "osdu-az-principal-client-secret" = var.osdu_az_principal_client_secret
    "osdu-az-principal-resource" = var.osdu_az_principal_resource
    "osdu-az-principal-tenant-id" = var.osdu_az_principal_tenant_id
    "osdu-dag-sync-key"           = data.local_file.dag_sync_key_file.content_base64
  }
}

module "keyvault_policy" {
  # Module Path
    source = "../../modules/keyvault-policy"
    vault_id = module.keyvault.id
    tenant_id = local.tenant_id
    object_ids = [azurerm_user_assigned_identity.main.principal_id]
}

module "appinsights" {
  source = "../../modules/app-insights"
  name   = local.appinsights_name
  resource_group_name = module.resource_group.name  
}


#-------------------------------
# Azure Pod Identity
#-------------------------------

#-------------------------------
# Install aad pod identity
#-------------------------------
resource "helm_release" "aad-pod-identity" {
  name          = "aad-pod-identity"
  chart         = "aad-pod-identity"
  namespace     = "kube-system"
  repository    = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  depends_on = [kubernetes_namespace.airflow_namespace]
}
#-------------------------------
# setup aad pod identity
#-------------------------------
resource "azurerm_user_assigned_identity" "main" {
  name                = local.user_assigned_identity_name
  resource_group_name = data.azurerm_resource_group.aks_node_resource_group.name
  location            = module.resource_group.location
}

data "azurerm_resource_group" "aks_node_resource_group" {
  name    = module.aks.node_resource_group
}

resource "azurerm_role_assignment" "role-usi-aks-mic" {
  role_definition_name = "Managed Identity Operator"
  principal_id = azurerm_user_assigned_identity.main.principal_id
  scope = data.azurerm_resource_group.aks_node_resource_group.id
  depends_on = [azurerm_user_assigned_identity.main,module.aks]
}
resource "azurerm_role_assignment" "role-usi-aks-vmc" {
  role_definition_name = "Virtual Machine Contributor"
  principal_id = azurerm_user_assigned_identity.main.principal_id
  scope = data.azurerm_resource_group.aks_node_resource_group.id
  depends_on = [azurerm_user_assigned_identity.main, module.aks]
}
#-------------------------------
# generate aad pod identity deployment YAML
#-------------------------------
resource "local_file" "azure_identity_yaml" {
  filename = local.auzre_identity_yaml
  content = templatefile( local.auzre_identity_template_yaml,
                {
                  identity_name = local.user_assigned_identity_name,
                  identity_id = azurerm_user_assigned_identity.main.id,
                  client_id = azurerm_user_assigned_identity.main.client_id 
                }
              )
}

resource "local_file" "azure_identity_binding_yaml" {
  filename = local.azure_identity_binding_yaml
  content = templatefile(local.azure_identity_binding_template_yaml,
                {
                  identity_name = local.user_assigned_identity_name
                }
              )
}

#-------------------------------
# deploy aad pod identity and binding
#-------------------------------
resource "kubectl_manifest" "identity-manifest" {
  yaml_body   = local_file.azure_identity_yaml.content
  depends_on  = [helm_release.aad-pod-identity]
}

resource "kubectl_manifest" "identity-binding-manifest" {
  yaml_body   = local_file.azure_identity_binding_yaml.content
  depends_on  = [kubectl_manifest.identity-manifest]
}








#-------------------------------
# Azure Kubernetes Service
#-------------------------------
module "aks" {
  source = "../../modules/aks"

  name                     = local.cluster_name
  resource_group_name      = module.resource_group.name
  dns_prefix               = local.cluster_name
  # service_principal_id     = module.service_principal.client_id
  # service_principal_secret = module.service_principal.client_secret
  service_principal_id     = var.client_id
  service_principal_secret = var.client_secret
  agent_vm_count           = var.agent_vm_count
  agent_vm_size            = var.agent_vm_size
  kubernetes_version       = "1.17.7"
  ssh_public_key = "${trimspace(tls_private_key.key.public_key_openssh)} k8sadmin"
  vnet_subnet_id = module.network.subnets.0

  resource_tags = {
    iac = "terraform"
  }
}


#-------------------------------
# Azure PostgreSQL database
#-------------------------------
module "postgresql" {
  source = "../../modules/postgresql"
  postgresql_login         = var.postgresqllogin
  postgresql_password      = var.postgresqlpwd
  postgresql_server_name   = local.postgresql_server
  resource_group_name      = module.resource_group.name
}


#-------------------------------
# Azure Redis Cache Service
#-------------------------------
module "redis" {
  source = "../../modules/redis-cache"
  name                     = local.redis_server
  resource_group_name      = module.resource_group.name          
}


#-------------------------------
# Install external secrets
#-------------------------------


resource "helm_release" "external-secrets" {
  name = "external-secrets"
  repository = "https://godaddy.github.io/kubernetes-external-secrets/"
  chart = "kubernetes-external-secrets"
  # values = [local_file.external_secret_values_yaml.content]
  set {
    name = "podLabels.aadpodidbinding"
    value = local.user_assigned_identity_name
  }
  set {
    name = "image.tag"
    value = "5.0.0"
  }
  set {
    name = "env.POLLER_INTERVAL_MILLISECONDS"
    value = 30000
  }
  depends_on = [kubectl_manifest.identity-binding-manifest] 
}

#-------------------------------
# generate external secret YAML
#-------------------------------

resource "local_file" "external_secret_values_yaml" {
  filename = local.external_secret_values_yaml
  content = templatefile(local.external_secret_values_template_yaml,
                {
                  identity_name = local.user_assigned_identity_name
                }
              )
}

resource "local_file" "osdu_dag_sync_secret_yaml" {
  filename = local.osdu_dag_sync_secret_yaml
  content = templatefile(local.osdu_dag_sync_secret_template_yaml,
                {
                  airflow_namespace = local.airflow_namespace,
                  keyvault_name     = local.keyvault_name                 
                }
            )
}

resource "local_file" "osdu_airflow_secret_yaml" {
  filename = local.osdu_airflow_secret_yaml
  content = templatefile(local.osdu_airflow_secret_template_yaml,
                {
                  airflow_namespace = local.airflow_namespace,
                  keyvault_name     = local.keyvault_name                 
                }
            )
}

resource "local_file" "osdu_az_principal_yaml" {
  filename = local.osdu_az_principal_yaml
  content = templatefile(local.osdu_az_principal_template_yaml,
              {
                airflow_namespace = local.airflow_namespace,
                keyvault_name     = local.keyvault_name
              }
            )
}

#-------------------------------
# setup external secret mapping
#-------------------------------

resource "kubectl_manifest" "secret-osdu-az-principal" {
  yaml_body  = local_file.osdu_az_principal_yaml.content
  depends_on = [helm_release.external-secrets, module.keyvault_secret]
}

resource "kubectl_manifest" "configmap-airflow-remote-log" {
  yaml_body = local_file.configmap_airflow_remote_log.content
  depends_on = [kubernetes_namespace.airflow_namespace]
}

resource "kubectl_manifest" "dag-sync-secret" {
  yaml_body = local_file.osdu_dag_sync_secret_yaml.content
  depends_on = [helm_release.external-secrets, module.keyvault_secret]
}

resource "kubectl_manifest" "airflow-secret" {
  yaml_body = local_file.osdu_airflow_secret_yaml.content
  depends_on = [helm_release.external-secrets,module.keyvault_secret]
}



#-------------------------------
# Airflow
#-------------------------------

resource "local_file" "airflow_helm_values" {
  filename = local.airflow_helm_values_yaml
  content = templatefile(local.airflow_helm_values_template_yaml,
              {
                  postgresql_host   = module.postgresql.server_fqdn,
                  postgresql_user   = local.postgresql_login
                  redis_host        = module.redis.hostname
              }
            ) 
}

resource "local_file" "configmap_airflow_remote_log" {
  filename = local.configmap_airflow_remote_log_yaml
  content = templatefile(local.configmap_airflow_remote_log_template_yaml,
              {
                  airflow_namespace = local.airflow_namespace,
                  keyvault_name     = local.keyvault_name
              }
            )
}


resource "null_resource" "helm_local_cache" {
  provisioner "local-exec" {
    command = "echo ${var.common_repository_password} | helm registry login ${var.common_repository} --username ${var.common_repository_username} --password-stdin && helm chart pull ${local.airflow_helm_chart} && helm chart export ${local.airflow_helm_chart} --destination ${local.airflow_helm_local_chart_dir}"
  }
}

resource "helm_release" "airflow" {
  name  ="airflow"
  namespace = local.airflow_namespace
  chart = local.airflow_helm_local_chart
  values = [local_file.airflow_helm_values.content]
  depends_on = [kubectl_manifest.secret-osdu-az-principal,
                kubectl_manifest.configmap-airflow-remote-log,
                kubectl_manifest.dag-sync-secret,
                kubectl_manifest.airflow-secret,
                null_resource.helm_local_cache]
}

resource "helm_release" "traefik" {
  name  ="traefik"
  # repository = "https://kubernetes-charts.storage.googleapis.com"
  namespace  = "traefik"
  chart ="stable/traefik"
  set {
    name  = "kubernetes.ingressClass"
    value = "traefik"
  }
  set {
    name  = "kubernetes.ingressEndpoint.useDefaultPublishedService"
    value = "true"
  }
  set {
    name  = "rbac.enable"
    value = "true"
  }
  depends_on = [module.aks]
}

#-------------------------------
# create namespace for airflow
#-------------------------------
resource "kubernetes_namespace" "airflow_namespace" {
  metadata{
    name  = local.airflow_namespace
  }
  depends_on = [module.aks]
}

resource "kubernetes_config_map" "appinsights_config_map" {
  metadata {
    name = "appinsights-config"
    namespace = local.airflow_namespace
  }
  data = {
    "appinsightsconfig.js" = local_file.appinsights_statsd_config.content
  }
  depends_on = [kubernetes_namespace.airflow_namespace]
}





#-------------------------------
# appinsights statsd Kubernetes deployment
#-------------------------------

resource "local_file" "appinsights_statsd_config" {
  filename = local.appinsights_statsd_config_js
  content  = templatefile(local.appinsights_statsd_config_template_js,
               {
                  airflow_instance_name = local.airflow_instance_name
                  appinsights_key       = module.appinsights.instrumentation_key
               }
            )
}
#-------------------------------
# Output Variables  (output.tf)
#-------------------------------

output "RESOURCE_GROUP" {
  value = module.resource_group.name
}

output "REGISTRY_NAME" {
  value = module.container_registry.name
}

output "CLUSTER_NAME" {
  value = local.cluster_name
}

output "AIRFLOW_LOG_STORAGE" {
  value = module.storage.name
}
# output "PRINCIPAL_ID" {
#   value = module.service_principal.client_id
# }

# output "PRINCIPAL_SECRET" {
#   value = module.service_principal.client_secret
# }

output "PRINCIPAL_ID" {
  value = var.client_id
}

output "PRINCIPAL_SECRET" {
  value = var.client_secret
}

output "id_rsa" {
  value = tls_private_key.key.private_key_pem
}

output "user_assigned_identity_id" {
  value = azurerm_user_assigned_identity.main.id
}

output "user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.main.client_id
}

output "user_assigned_identity_principal_id" {
  value = azurerm_user_assigned_identity.main.principal_id
}

output "kubeconfig" {
  value = module.aks.kube_config_path
}

# output "aks_node_resource_group" {
#   value = module.aks.node_resource_group
# }