include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/05-monitoring"
}

dependency "gke" {
  config_path = "../04-gke"
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

inputs = {
  observability_config   = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/monitoring-and-logging/values.yaml"))
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}