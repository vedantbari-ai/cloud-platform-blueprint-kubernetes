terraform {
  required_version = ">= 1.15.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}


# 1. EXPLICIT KUBERNETES PROVIDER (Fixes the connection refused error)
provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

# 2. HELM PROVIDER
provider "helm" {
  kubernetes = {
    host                   = "https://${var.cluster_endpoint}"
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}