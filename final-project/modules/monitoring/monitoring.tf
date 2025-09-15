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

# =========================
# Jenkins: Server metrics
# =========================
resource "kubernetes_manifest" "jenkins_service_monitor" {
  count = var.enable_jenkins_monitoring ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "jenkins"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/instance"  = "jenkins"
          "app.kubernetes.io/component" = "jenkins-controller"
        }
      }
      namespaceSelector = {
        matchNames = ["jenkins"]
      }
      endpoints = [{
        port     = "http"
        path     = "/prometheus"
        interval = "30s"
      }]
    }
  }

  depends_on = [helm_release.prometheus]
}

# =========================
# ArgoCD: Server metrics
# =========================
resource "kubernetes_manifest" "argocd_service_monitor" {
  count = var.enable_argocd_monitoring ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "argocd"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/instance" = "argo-cd"
          "app.kubernetes.io/name"     = "argocd-server-metrics"
        }
      }
      namespaceSelector = {
        matchNames = ["argocd"]
      }
      endpoints = [{
        port     = "http-metrics"
        path     = "/metrics"
        interval = "30s"
        relabelings = [{
          targetLabel = "job"
          replacement = "argocd-server-metrics"
        }]
      }]
    }
  }

  depends_on = [helm_release.prometheus]
}

# =========================
# ArgoCD: Repo-server metrics Service
# =========================
resource "kubernetes_manifest" "argocd_repo_metrics_service" {
  count = var.enable_argocd_monitoring ? 1 : 0
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "argo-cd-argocd-repo-server-metrics"
      namespace = "argocd"
      labels = {
        "app.kubernetes.io/instance" = "argo-cd"
        "app.kubernetes.io/name"     = "argocd-repo-server-metrics"
        "app.kubernetes.io/part-of"  = "argocd"
      }
    }
    spec = {
      selector = {
        # селектор на поди repo-server
        "app.kubernetes.io/name"    = "argocd-repo-server"
        "app.kubernetes.io/part-of" = "argocd"
      }
      ports = [{
        name       = "metrics"
        port       = 8084
        targetPort = 8084
        protocol   = "TCP"
      }]
      type = "ClusterIP"
    }
  }
}

# =========================
# ArgoCD: Repo-server ServiceMonitor
# =========================
resource "kubernetes_manifest" "argocd_repo_monitor" {
  count = var.enable_argocd_monitoring ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "argocd-repo-server"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "argocd-repo-server-metrics"
          "app.kubernetes.io/instance" = "argo-cd"
        }
      }
      namespaceSelector = {
        matchNames = ["argocd"]
      }
      endpoints = [{
        port     = "metrics"
        path     = "/metrics"
        interval = "30s"
        relabelings = [{
          targetLabel = "job"
          replacement = "argocd-repo-server-metrics"
        }]
      }]
    }
  }
}

# =========================
# ArgoCD: Application Controller metrics Service
# =========================
resource "kubernetes_manifest" "argocd_app_controller_metrics_service" {
  count = var.enable_argocd_monitoring ? 1 : 0
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "argo-cd-argocd-application-controller-metrics"
      namespace = "argocd"
      labels = {
        "app.kubernetes.io/instance" = "argo-cd"
        "app.kubernetes.io/name"     = "argocd-application-controller-metrics"
        "app.kubernetes.io/part-of"  = "argocd"
      }
    }
    spec = {
      selector = {
        "app.kubernetes.io/name"    = "argocd-application-controller"
        "app.kubernetes.io/part-of" = "argocd"
      }
      ports = [{
        name       = "metrics"
        port       = 8082
        targetPort = 8082
        protocol   = "TCP"
      }]
      type = "ClusterIP"
    }
  }
}

resource "kubernetes_manifest" "argocd_app_controller_monitor" {
  count = var.enable_argocd_monitoring ? 1 : 0
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "argocd-application-controller"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "argocd-application-controller-metrics"
          "app.kubernetes.io/instance" = "argo-cd"
        }
      }
      namespaceSelector = {
        matchNames = ["argocd"]
      }
      endpoints = [{
        port     = "metrics"
        path     = "/metrics"
        interval = "30s"
        relabelings = [{
          targetLabel = "job"
          replacement = "argocd-application-controller-metrics"
        }]
      }]
    }
  }
}

# Create custom dashboards ConfigMap for Grafana
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "custom-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "argocd-dashboard.json"  = file("${path.module}/dashboards/argocd-dashboard.json")
    "jenkins-dashboard.json" = file("${path.module}/dashboards/jenkins-dashboard.json")
  }

  depends_on = [helm_release.prometheus]
}
