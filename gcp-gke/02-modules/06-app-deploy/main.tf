resource "helm_release" "app_deployment" {
  name             = var.release_name
  chart            = var.chart_path
  namespace        = var.namespace
  create_namespace = true
  timeout          = var.timeout

  values = [yamlencode(var.app_values)]
}