provider "azurerm" {
  features {}
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = "iac-terraform"
  location = "eastus2"
}

module "service_principal" {
  source = "../../modules/service-principal"

  name     = format("iac-terraform-%s", module.resource_group.random)
  role     = "Contributor"
  scopes   = [module.resource_group.id]
  end_date = "1W"
}

module "network" {
  source = "../../modules/network"

  name                = format("iac-terraform-vnet-%s", module.resource_group.random)
  resource_group_name = module.resource_group.name
  address_space       = "10.10.0.0/16"
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = ["10.10.1.0/24"]
  subnet_names        = ["Cluster-Subnet"]
}

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

data "azurerm_client_config" "current" {}

module "aks-gitops" {
  source = "../"

  name                     = format("iac-terraform-cluster-%s", module.resource_group.random)
  resource_group_name      = module.resource_group.name
  dns_prefix               = format("iac-terraform-cluster-%s", module.resource_group.random)
  service_principal_id     = module.service_principal.client_id
  service_principal_secret = module.service_principal.client_secret

  ssh_public_key = "${trimspace(tls_private_key.key.public_key_openssh)} k8sadmin"
  vnet_subnet_id = module.network.subnets.0

  resource_tags = {
    iac = "terraform"
  }
}