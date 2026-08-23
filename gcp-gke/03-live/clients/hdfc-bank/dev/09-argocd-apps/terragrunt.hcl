include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/09-argocd-apps"
}

dependency "gke" {
  config_path = "../04-gke"
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

dependency "argocd" {
  config_path = "../08-argocd"
  mock_outputs = {
    argocd_status = "Deployed"
  }
}

locals {
  client_name = include.root.locals.config.client.name
  env_name    = include.root.locals.config.environment

  apps_dir    = "${get_repo_root()}/gcp-gke/12-platform-config/clients/${local.client_name}/${local.env_name}/apps"
  app_files   = try(fileset(local.apps_dir, "*-values.yaml"), [])

  apps = {
    for f in local.app_files : 
    replace(f, "-values.yaml", "") => jsonencode(yamldecode(file("${local.apps_dir}/${f}")))
  }
}

inputs = {
  client_name            = local.client_name
  environment            = local.env_name
  git_repo_url           = "https://github.com/YOUR-ORG/YOUR-REPO.git"
  apps                   = local.apps
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}