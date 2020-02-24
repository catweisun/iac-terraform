##############################################################
# This module allows the creation of a Kubernetes Cluster
##############################################################

terraform {
  required_version = "~> 0.12.20"
  required_providers {
    azurerm = "~> 1.44"
  }
}