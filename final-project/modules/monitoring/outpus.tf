output "grafana_service_name" {
  value       = helm_release.prometheus.name
  description = "Grafana release name (used to construct service name)"
}
