output "vpc_id" {
  value = var.create_vpc ? google_compute_network.vpc[0].id : data.google_compute_network.existing[0].id
}

output "vpc_name" {
  value = var.create_vpc ? google_compute_network.vpc[0].name : data.google_compute_network.existing[0].name
}

output "subnet_id" {
  value = var.create_vpc ? google_compute_subnetwork.subnet[0].id : data.google_compute_subnetwork.existing[0].id
}

output "subnet_name" {
  value = var.create_vpc ? google_compute_subnetwork.subnet[0].name : data.google_compute_subnetwork.existing[0].name
}

output "pod_range_name" {
  value = var.pod_range_name
}

output "svc_range_name" {
  value = var.svc_range_name
}