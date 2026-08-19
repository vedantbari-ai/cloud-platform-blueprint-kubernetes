# 1. Firewall Rule to Allow Google IAP TCP Forwarding (Port 22 SSH)
# Google's IAP IP range for tunneling is 35.235.240.0/20
resource "google_compute_firewall" "allow_iap_ssh" {
  count   = var.create_bastion ? 1 : 0
  name    = "${var.bastion_name}-allow-iap-ssh"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]
}

# 2. IAP-Secured Bastion Host (GCE Instance)
resource "google_compute_instance" "bastion" {
  count        = var.create_bastion ? 1 : 0
  name         = var.bastion_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["allow-iap-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = var.subnet_name
    # NOTE: No `access_config` block is included here. 
    # This ensures the instance gets NO external public IP address.
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  labels = var.tags

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}