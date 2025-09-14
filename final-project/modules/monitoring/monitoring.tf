resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# Prometheus Helm Release
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", {
      storage_class           = var.storage_class
      prometheus_storage_size = var.prometheus_storage_size
      grafana_admin_password  = var.grafana_admin_password
      retention_days          = var.retention_days
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# ServiceMonitor for Jenkins
resource "kubernetes_manifest" "jenkins_service_monitor" {
  count = var.enable_jenkins_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "jenkins"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app     = "jenkins"
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "jenkins"
        }
      }
      namespaceSelector = {
        matchNames = ["jenkins"]
      }
      endpoints = [{
        port     = "http"
        interval = "30s"
        path     = "/prometheus"
      }]
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}

# ServiceMonitor for ArgoCD
resource "kubernetes_manifest" "argocd_service_monitor" {
  count = var.enable_argocd_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "argocd"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app     = "argocd"
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "argocd"
        }
      }
      namespaceSelector = {
        matchNames = ["argocd"]
      }
      endpoints = [{
        port     = "metrics"
        interval = "30s"
      }]
    }
  }

  depends_on = [
    helm_release.prometheus
  ]
}
