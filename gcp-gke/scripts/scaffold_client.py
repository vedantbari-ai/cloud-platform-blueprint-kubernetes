#!/usr/bin/env python3
import os
import sys
import yaml

def load_yaml(file_path):
    if not os.path.exists(file_path):
        print(f"❌ Error: Configuration file not found at {file_path}")
        sys.exit(1)
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def write_file_if_changed(file_path, content):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    if os.path.exists(file_path):
        with open(file_path, 'r') as f:
            existing_content = f.read()
        if existing_content == content:
            print(f"  ⚡ Up to date: {os.path.basename(os.path.dirname(file_path))}")
            return
    with open(file_path, 'w') as f:
        f.write(content)
    print(f"  ✔ Created/Updated: {os.path.basename(os.path.dirname(file_path))}")

def generate_terragrunt_files(config_path):
    config = load_yaml(config_path)
    client_name = config.get('client', {}).get('name')
    environment = config.get('environment', 'dev')
    
    if not client_name:
        print("❌ Error: 'client.name' is missing in the YAML configuration.")
        sys.exit(1)

    print(f"🚀 Processing infrastructure layout for client: '{client_name}' ({environment})...")

    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    live_dir = os.path.join(repo_root, "03-live", "clients", client_name, environment)
    
    vpc_enabled = config.get('vpc', {}).get('create', False)
    bastion_enabled = config.get('bastion', {}).get('create', False)
    filestore_enabled = config.get('storage', {}).get('filestore', {}).get('create', False)

    config_rel_path = f"../../../../../12-platform-config/clients/{client_name}/infra/{environment}.yaml"

    # 1. Bootstrap Layer
    bootstrap_content = f'''include "root" {{
  path   = find_in_parent_folders("root.hcl")
  expose = true
}}

terraform {{
  source = "${{get_repo_root()}}/gcp-gke/02-modules/01-bootstrap"
}}

locals {{
  infra_config = yamldecode(file("{config_rel_path}"))
}}

inputs = {{
  project_id        = local.infra_config.gcp.project_id
  state_bucket_name = local.infra_config.bootstrap.state_bucket_name
}}
'''
    write_file_if_changed(os.path.join(live_dir, "01-bootstrap", "terragrunt.hcl"), bootstrap_content)

    # 2. VPC Layer
    if vpc_enabled:
        vpc_content = f'''include "root" {{
  path   = find_in_parent_folders("root.hcl")
  expose = true
}}

terraform {{
  source = "${{get_repo_root()}}/gcp-gke/02-modules/02-vpc"
}}

locals {{
  infra_config = yamldecode(file("{config_rel_path}"))
}}

inputs = {{
  project_id     = local.infra_config.gcp.project_id
  region         = local.infra_config.gcp.region
  vpc_name       = local.infra_config.vpc.vpc_name
  network_cidr   = local.infra_config.vpc.network_cidr
  subnet_name    = local.infra_config.vpc.subnet_name
  subnet_cidr    = local.infra_config.vpc.subnet_cidr
  pod_range_name = local.infra_config.vpc.pod_range_name
  pod_range_cidr = local.infra_config.vpc.pod_range_cidr
  svc_range_name = local.infra_config.vpc.svc_range_name
  svc_range_cidr = local.infra_config.vpc.svc_range_cidr
}}
'''
        write_file_if_changed(os.path.join(live_dir, "02-vpc", "terragrunt.hcl"), vpc_content)

    # 3. Bastion Layer
    if bastion_enabled:
        bastion_content = f'''include "root" {{
  path   = find_in_parent_folders("root.hcl")
  expose = true
}}

terraform {{
  source = "${{get_repo_root()}}/gcp-gke/02-modules/03-bastion"
}}

dependency "vpc" {{
  config_path = "../02-vpc"
  mock_outputs = {{
    vpc_name    = "mock-vpc"
    subnet_name = "mock-subnet"
  }}
}}

locals {{
  infra_config = yamldecode(file("{config_rel_path}"))
}}

inputs = {{
  project_id   = local.infra_config.gcp.project_id
  zone         = local.infra_config.gcp.zone
  name         = local.infra_config.bastion.name
  machine_type = local.infra_config.bastion.machine_type
  disk_size_gb = local.infra_config.bastion.disk_size_gb
  vpc_name     = dependency.vpc.outputs.vpc_name
  subnet_name  = dependency.vpc.outputs.subnet_name
}}
'''
        write_file_if_changed(os.path.join(live_dir, "03-bastion", "terragrunt.hcl"), bastion_content)

    # 4. GKE Layer
    gke_content = f'''include "root" {{
  path   = find_in_parent_folders("root.hcl")
  expose = true
}}

terraform {{
  source = "${{get_repo_root()}}/gcp-gke/02-modules/04-gke"
}}

dependency "vpc" {{
  config_path = "../02-vpc"
  mock_outputs = {{
    vpc_name       = "mock-vpc"
    subnet_name    = "mock-subnet"
    pod_range_name = "mock-pods"
    svc_range_name = "mock-services"
  }}
}}

locals {{
  infra_config = yamldecode(file("{config_rel_path}"))
}}

inputs = {{
  project_id              = local.infra_config.gcp.project_id
  region                  = local.infra_config.gcp.region
  zone                    = local.infra_config.gcp.zone
  cluster_name            = local.infra_config.gke.cluster_name
  cluster_version         = local.infra_config.gke.cluster_version
  release_channel         = local.infra_config.gke.release_channel
  machine_type            = local.infra_config.gke.machine_type
  node_count              = local.infra_config.gke.node_count
  disk_size_gb            = local.infra_config.gke.disk_size_gb
  enable_autoscaling      = local.infra_config.gke.enable_autoscaling
  min_nodes               = local.infra_config.gke.min_nodes
  max_nodes               = local.infra_config.gke.max_nodes
  delete_protection       = local.infra_config.gke.delete_protection
  enable_filestore_csi    = local.infra_config.gke.enable_filestore_csi
  secretManagerEnabled    = local.infra_config.gke.secretManagerEnabled
  workloadIdentityEnabled = local.infra_config.gke.workloadIdentityEnabled
  cluster_addons          = local.infra_config.gke.cluster_addons
  vpc_name                = dependency.vpc.outputs.vpc_name
  subnet_name             = dependency.vpc.outputs.subnet_name
  pod_range_name          = dependency.vpc.outputs.pod_range_name
  svc_range_name          = dependency.vpc.outputs.svc_range_name
}}
'''
    write_file_if_changed(os.path.join(live_dir, "04-gke", "terragrunt.hcl"), gke_content)

    # 5. Storage Class Layer
    if filestore_enabled:
        storage_content = f'''include "root" {{
  path   = find_in_parent_folders("root.hcl")
  expose = true
}}

terraform {{
  source = "${{get_repo_root()}}/gcp-gke/02-modules/07-storage-class"
}}

locals {{
  infra_config = yamldecode(file("{config_rel_path}"))
}}

inputs = {{
  project_id = local.infra_config.gcp.project_id
  region     = local.infra_config.gcp.region
  storage    = local.infra_config.storage
}}
'''
        write_file_if_changed(os.path.join(live_dir, "07-storage-class", "terragrunt.hcl"), storage_content)

    print(f"🎉 Infrastructure layout synchronization completed successfully for {client_name}!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 scaffold_client.py <path_to_infra_yaml>")
        sys.exit(1)
    generate_terragrunt_files(sys.argv[1])