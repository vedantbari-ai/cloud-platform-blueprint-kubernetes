variable "project_id" {
  type = string
}

variable "release_name" {
  type = string
}

variable "chart_path" {
  type = string
}

variable "namespace" {
  type = string
}

variable "timeout" {
  type    = number
  default = 600
}

variable "app_values" {
  type = any
}

variable "cluster_endpoint" {
  type        = string
  description = "The GKE cluster endpoint"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "The GKE cluster CA certificate"
}