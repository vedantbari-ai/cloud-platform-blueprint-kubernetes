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

inputs = {
  chart_path             = "${get_repo_root()}/gcp-gke/13-helm-charts-app"
  
  # Dynamically extracted from values.yaml
  release_name           = local.app_values.releaseName
  namespace              = local.app_values.namespace.name
  app_values             = local.app_values

  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}