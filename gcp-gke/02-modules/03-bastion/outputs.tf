output "bastion_name" {
  description = "Name of the deployed bastion host"
  value       = var.create_bastion ? google_compute_instance.bastion[0].name : null
}

output "bastion_private_ip" {
  description = "Internal IP address of the bastion host"
  value       = var.create_bastion ? google_compute_instance.bastion[0].network_interface[0].network_ip : null
}