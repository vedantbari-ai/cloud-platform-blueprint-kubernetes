output "gcs_bucket_name" {
  description = "The name of the GCS bucket created for Terraform state."
  value       = google_storage_bucket.terraform_state.name
}

output "gcs_bucket_id" {
  description = "The ID of the GCS bucket."
  value       = google_storage_bucket.terraform_state.id
}

output "kms_crypto_key_id" {
  description = "The ID of the KMS crypto key used for bucket encryption."
  value       = google_kms_crypto_key.terraform_state.id
}