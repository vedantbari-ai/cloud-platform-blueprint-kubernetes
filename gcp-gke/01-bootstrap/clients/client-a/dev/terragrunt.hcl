# For the initial bootstrap, we directly load the config from dev.yaml
# as the remote state backend (defined in a higher-level root.hcl) does not exist yet.
locals {
  config = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/infra/dev.yaml"))
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/01-bootstrap"
}

inputs = {
  project_id        = local.config.gcp.project_id
  region            = local.config.gcp.region
  state_bucket_name = local.config.bootstrap.state_bucket_name
  tags              = local.config.gcp.tags
}



