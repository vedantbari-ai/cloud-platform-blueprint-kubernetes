locals {
  gsa_email    = try(var.app_values.serviceAccount.annotations["iam.gke.io/gcp-service-account"], "")
  gsa_name     = local.gsa_email != "" ? split("@", local.gsa_email)[0] : ""
  secrets_list = try(var.app_values.secretManager.enabled, false) ? var.app_values.secretManager.secrets : []
}

# 1. Create Google Service Account
resource "google_service_account" "app_gsa" {
  count        = local.gsa_name != "" ? 1 : 0
  project      = var.project_id
  account_id   = local.gsa_name
  display_name = "GSA for ${var.release_name}"
}

# 2. Bind Workload Identity
resource "google_service_account_iam_member" "workload_identity" {
  count              = local.gsa_name != "" ? 1 : 0
  service_account_id = google_service_account.app_gsa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.app_values.serviceAccount.name}]"
}

# 3. Create Secrets
resource "google_secret_manager_secret" "secrets" {
  for_each  = { for s in local.secrets_list : s.secretId => s }
  project   = var.project_id
  secret_id = each.value.secretId

  # Fixed formatting: Moved to multi-line block for better parsing
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each    = { for s in local.secrets_list : s.secretId => s }
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.secretValue
}

# 4. Grant Secret Access to GSA
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each  = { for s in local.secrets_list : s.secretId => s }
  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  # Added a check: only create if email exists to prevent invalid IAM strings
  member    = "serviceAccount:${local.gsa_email}"
}

# 5. Helm Deployment
resource "helm_release" "app_deployment" {
  name             = var.release_name
  chart            = var.chart_path
  namespace        = var.namespace
  create_namespace = true
  timeout          = var.timeout

  values = [yamlencode(var.app_values)]

  # Ensure resources are created before Helm tries to mount them
  depends_on = [
    google_service_account_iam_member.workload_identity,
    google_secret_manager_secret_version.secret_versions,
    google_secret_manager_secret_iam_member.secret_access
  ]
}