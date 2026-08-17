variable "project_id" {
  description = "The GCP Project ID where bootstrap resources will be created"
  type        = string
}

variable "region" {
  description = "The primary GCP region for resources"
  type        = string
  default     = "asia-south1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform GCS state bucket"
  type        = string
}

variable "tags" {
  description = "Labels to apply to bootstrap resources"
  type        = map(string)
  default     = {}
}