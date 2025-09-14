#-------------Jenkins-----------------

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

#-------------Argo CD-----------------

output "argo_cd_server_service" {
  value = module.argo_cd.argo_cd_server_service
}

output "argo_cd_admin_password" {
  value = module.argo_cd.admin_password
}

#-------------Grafana + Prometheus-----------------

output "grafana_service_name" {
  value = module.monitoring.grafana_service_name
}