variable "namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "56.0.0"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "gp3"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus PVC"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "retention_days" {
  description = "Number of days to retain Prometheus data"
  type        = number
  default     = 15
}

variable "enable_jenkins_monitoring" {
  description = "Enable monitoring for Jenkins"
  type        = bool
  default     = false
}

variable "enable_argocd_monitoring" {
  description = "Enable monitoring for ArgoCD"
  type        = bool
  default     = false
}
