include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/06-app-deploy"
}

dependency "gke" {
  config_path = "../../04-gke"
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

locals {
  app_values = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/apps/test-app-values.yaml"))
}


inputs = {
  chart_path             = "${get_repo_root()}/gcp-gke/13-helm-charts-app/generic-app" # <--- Added /generic-app here
  release_name           = local.app_values.releaseName
  namespace              = local.app_values.namespace.name
  app_values             = local.app_values
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
  timeout                = local.app_values.timeout
}