include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/06-app-deploy"
}

dependency "gke" {
  config_path = "../../04-gke" # <-- Fixed relative path to point to dev/04-gke
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

dependency "iam_secrets" {
  config_path = "../../iam-secrets"
  mock_outputs = {
    gsa_email = "mock-gsa@project.iam.gserviceaccount.com"
  }
}

locals {
  app_values = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/apps/frontend-web-values.yaml"))
}

inputs = {
  chart_path             = "${get_repo_root()}/gcp-gke/13-helm-charts-app/generic-app"
  release_name           = local.app_values.releaseName
  namespace              = local.app_values.namespace.name
  timeout                = local.app_values.timeout
  app_values             = local.app_values
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}