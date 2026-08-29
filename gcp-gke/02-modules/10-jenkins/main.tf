


data "google_client_config" "default" {}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  namespace        = kubernetes_namespace.jenkins.metadata[0].name
  create_namespace = true
  version          = "5.4.1"
  timeout          = 1200

  values = [
    templatefile(var.yaml_path, {
      cluster_endpoint       = var.cluster_endpoint
      cluster_ca_certificate = var.cluster_ca_certificate
      dockerhub_username     = var.dockerhub_username
      dockerhub_token        = var.dockerhub_token
    })
  ]
}