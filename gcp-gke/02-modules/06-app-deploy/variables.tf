variable "chart_path" {
  description = "Path to the local generic Helm chart"
  type        = string
}

variable "release_name" {
  description = "Helm release name"
  type        = string
}

variable "namespace" {
  description = "Target Kubernetes namespace for the application"
  type        = string
}

variable "app_values" {
  description = "Map of configuration values for the application"
  type        = any
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "timeout" {
  description = "Timeout in seconds for the Helm release operation"
  type        = number
  default     = 300
}
