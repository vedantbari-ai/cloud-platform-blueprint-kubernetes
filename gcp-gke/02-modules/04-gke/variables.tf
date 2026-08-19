variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "cluster_name" { type = string }
variable "cluster_version" { type = string }
variable "release_channel" { type = string }
variable "vpc_name" { type = string }
variable "subnet_name" { type = string }
variable "pod_range_name" { type = string }
variable "svc_range_name" { type = string }

variable "machine_type" { type = string }
variable "node_count" { type = number }
variable "disk_size_gb" { type = number }
variable "disk_type" { type = string }
variable "min_nodes" { type = number }
variable "max_nodes" { type = number }
variable "enable_autoscaling" { type = bool }
variable "delete_protection" { type = bool }
variable "enable_filestore_csi" { type = bool }

variable "workload_identity_enabled" {
  type    = bool
  default = true
}

variable "secret_manager_enabled" {
  type    = bool
  default = false
}

variable "cluster_addons" {
  type = object({
    http_load_balancing        = bool
    horizontal_pod_autoscaling = bool
    gce_csi_driver             = bool
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
