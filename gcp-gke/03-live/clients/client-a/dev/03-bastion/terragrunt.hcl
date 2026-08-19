include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/03-bastion"
}

dependency "vpc" {
  config_path = "../02-vpc"
  mock_outputs = {
    vpc_name    = "mock-vpc"
    subnet_name = "mock-subnet"
  }
}

inputs = {
  project_id     = include.root.locals.config.gcp.project_id
  region         = include.root.locals.config.gcp.region
  zone           = include.root.locals.config.gcp.zone
  create_bastion = include.root.locals.config.bastion.create
  bastion_name   = include.root.locals.config.bastion.name
  machine_type   = include.root.locals.config.bastion.machine_type
  disk_size_gb   = include.root.locals.config.bastion.disk_size_gb
  vpc_name       = dependency.vpc.outputs.vpc_name
  subnet_name    = dependency.vpc.outputs.subnet_name
  tags           = include.root.locals.config.gcp.tags
}