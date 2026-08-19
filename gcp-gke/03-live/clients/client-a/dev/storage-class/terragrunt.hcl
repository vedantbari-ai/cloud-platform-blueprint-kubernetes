include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/07-storage-class"
}

dependency "gke" {
  config_path = "../04-gke"
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

dependency "vpc" {
  config_path = "../02-vpc"
  mock_outputs = {
    network_name = "default-vpc"
  }
}

locals {
  sc_values = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/storage/storage-class-values.yaml"))
}

inputs = {
  storage_class_name     = local.sc_values.storageClassName
  storage_provisioner    = local.sc_values.storageProvisioner
  tier                   = local.sc_values.tier
  vpc_network_name       = try(dependency.vpc.outputs.network_name, local.sc_values.vpcNetworkName)
  
  # Pass GKE cluster credentials
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}