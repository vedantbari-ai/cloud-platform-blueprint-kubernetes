variable "project_id" {
  description = "The GCP project ID to host the resources."
  type        = string
}

variable "location" {
  description = "The GCP region where the GCS bucket and KMS key will be created."
  type        = string
}

variable "bucket_name" {
  description = "The globally unique name for the GCS bucket that will store Terraform state."
  type        = string
}

variable "key_ring_name" {
  description = "The name for the KMS key ring."
  type        = string
  default     = "terraform-state-keyring"
}

variable "crypto_key_name" {
  description = "The name for the KMS crypto key."
  type        = string
  default     = "terraform-state-key"
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be destroyed from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  type        = bool
  default     = false
}

variable "labels" {
  description = "A map of labels to assign to the GCS bucket."
  type        = map(string)
  default = {
    "managed-by" = "terraform"
    "component"  = "bootstrap"
  }
}