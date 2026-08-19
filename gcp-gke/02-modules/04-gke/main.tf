# 1. GKE Cluster (Zonal, Cost-Optimized for R&D)
resource "google_container_cluster" "primary" {
  name                     = var.cluster_name
  location                 = var.zone
  project                  = var.project_id
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.delete_protection

  network    = var.vpc_name
  subnetwork = var.subnet_name

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_range_name
    services_secondary_range_name = var.svc_range_name
  }

  release_channel {
    channel = var.release_channel
  }

# Replace the static block with this dynamic block
  dynamic "secret_manager_config" {
    for_each = var.secret_manager_enabled ? [1] : []
    content {
      enabled = true
    }
  }
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }



  addons_config {
    http_load_balancing {
      disabled = !var.cluster_addons.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.cluster_addons.horizontal_pod_autoscaling
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.cluster_addons.gce_csi_driver
    }
    # Add Filestore CSI Driver for NFS File Storage
    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi
    }
  }

  resource_labels = var.tags
}

# 2. Separately Managed Node Pool
resource "google_container_node_pool" "node_pool" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  project    = var.project_id
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    labels = var.tags
  }
}

