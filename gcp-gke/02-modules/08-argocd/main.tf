
# CORRECT: Use the data keyword block syntax to declare the data source
data "google_client_config" "default" {}

# provider "helm" {
#   kubernetes = {
#     host                   = "https://${var.cluster_endpoint}"
#     cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#     token                  = data.google_client_config.default.access_token
#   }
# }

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  version = "5.51.6"

  values = [
    yamlencode(var.argocd_config)
  ]
}
