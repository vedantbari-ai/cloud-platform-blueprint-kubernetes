############################################################
# KMS for State Bucket Encryption
############################################################

resource "google_kms_key_ring" "terraform_state" {
  project  = var.project_id
  name     = var.key_ring_name
  location = var.location
}

resource "google_kms_crypto_key" "terraform_state" {
  name            = var.crypto_key_name
  key_ring        = google_kms_key_ring.terraform_state.id
  rotation_period = "100000s" # Example rotation period

  lifecycle {
    prevent_destroy = true
  }
}

############################################################
# GCS Bucket for Terraform State
############################################################

resource "google_storage_bucket" "terraform_state" {
  project                  = var.project_id
  name                     = var.bucket_name
  location                 = var.location
  force_destroy            = var.force_destroy
  storage_class            = "STANDARD"
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state.id
  }

  labels = var.labels
}

############################################################
# IAM Binding for GCS Bucket
############################################################

data "google_project" "project" {
  project_id = var.project_id
}

# Grant the KMS Encrypter/Decrypter role to the GCS service account for the project
# This allows GCS to use the key to encrypt/decrypt objects in the bucket.
resource "google_kms_crypto_key_iam_member" "gcs_kms_access" {
  crypto_key_id = google_kms_crypto_key.terraform_state.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}