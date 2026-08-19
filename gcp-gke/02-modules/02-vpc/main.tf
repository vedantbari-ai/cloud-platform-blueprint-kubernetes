# 1. VPC Network
resource "google_compute_network" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2. Single Regional Subnet with GKE Secondary Ranges
resource "google_compute_subnetwork" "subnet" {
  count                    = var.create_vpc ? 1 : 0
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc[0].id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pod_range_name
    ip_cidr_range = var.pod_range_cidr
  }

  secondary_ip_range {
    range_name    = var.svc_range_name
    ip_cidr_range = var.svc_range_cidr
  }
}

# 3. Cloud Router & Cloud NAT for Outbound Internet
resource "google_compute_router" "router" {
  count   = var.create_vpc ? 1 : 0
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.vpc[0].id
}

resource "google_compute_router_nat" "nat" {
  count                              = var.create_vpc ? 1 : 0
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 4. Data Source for Existing VPC
data "google_compute_network" "existing" {
  count = var.create_vpc ? 0 : 1
  name  = var.vpc_name
}

data "google_compute_subnetwork" "existing" {
  count  = var.create_vpc ? 0 : 1
  name   = var.subnet_name
  region = var.region
}