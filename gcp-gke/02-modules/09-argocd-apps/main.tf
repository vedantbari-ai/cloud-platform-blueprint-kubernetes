terraform {
  required_version = ">= 1.15.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

variable "cluster_endpoint"       { type = string }
variable "cluster_ca_certificate" { type = string }
variable "client_name"            { type = string }
variable "environment"            { type = string }
variable "git_repo_url"           { type = string }
variable "apps" { 
  type = map(string) 
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

resource "kubernetes_manifest" "argo_applications" {
  for_each = var.apps

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.client_name}-${var.environment}-${each.key}"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "HEAD"
        path           = "gcp-gke/13-helm-charts-app/generic-app"
        helm = {
          valueFiles = [
            "gcp-gke/12-platform-config/clients/${var.client_name}/${var.environment}/apps/${each.key}-values.yaml"
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "${each.key}-${var.environment}"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}