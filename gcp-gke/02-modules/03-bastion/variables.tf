variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The primary GCP region"
  type        = string
}

variable "zone" {
  description = "The specific GCP zone for the bastion host"
  type        = string
}

variable "create_bastion" {
  description = "Boolean flag to create the bastion host"
  type        = bool
  default     = true
}

variable "bastion_name" {
  description = "Name of the bastion instance"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type (cost-optimized for R&D)"
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet where the bastion will reside"
  type        = string
}

variable "tags" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}