variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The primary GCP region"
  type        = string
}

variable "zone" {
  description = "The zone for the zonal GKE cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "release_channel" {
  description = "GKE release channel (e.g. REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "pod_range_name" {
  description = "Secondary IP range name for pods"
  type        = string
}

variable "svc_range_name" {
  description = "Secondary IP range name for services"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Initial node count per zone"
  type        = number
  default     = 1
}

variable "disk_size_gb" {
  description = "Size of node boot disk in GB"
  type        = number
  default     = 30
}

variable "enable_autoscaling" {
  description = "Enable node pool autoscaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Minimum nodes for autoscaling"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 2
}

variable "delete_protection" {
  description = "Enable cluster deletion protection"
  type        = bool
  default     = false
}

variable "cluster_addons" {
  description = "Addons configuration map"
  type = object({
    http_load_balancing        = bool
    horizontal_pod_autoscaling = bool
    gce_csi_driver             = bool
  })
}

variable "tags" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}


variable "enable_filestore_csi" {
  description = "Enable the GCP Filestore CSI driver for NFS file storage"
  type        = bool
  default     = true
}

variable "secret_manager_enabled" {
  description = "Enable the Secret Manager driver"
  type        = bool
  default     = false
}

variable "workload_identity_enabled" {
  description = "Enable the worload identity"
  type        = bool
  default     = false
}
