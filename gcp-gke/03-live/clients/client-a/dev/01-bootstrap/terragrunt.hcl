include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../../02-modules/01-bootstrap"
}

inputs = {
  project_id        = include.root.locals.config.gcp.project_id
  region            = include.root.locals.config.gcp.region
  state_bucket_name = include.root.locals.config.bootstrap.state_bucket_name
  tags              = include.root.locals.config.gcp.tags
}


