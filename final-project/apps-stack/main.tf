# Підключаємо модуль k8s-external-secrets
module "k8s-external-secrets" {
  source               = "../modules/k8s-external-secrets"
  providers = {
    kubernetes = kubernetes.eks
  }
}

# Підключаємо модуль Jenkins
module "jenkins" {
  source                 = "../modules/jenkins"
  cluster_name           = data.terraform_remote_state.infra.outputs.eks_cluster_name
  oidc_provider_arn      = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  oidc_provider_url      = data.terraform_remote_state.infra.outputs.oidc_provider_url
  github_repo_url        = var.github_repo_url
  github_branch          = "final-project"
  jenkinsfile_dir        = "final-project/Django"
  jenkins_admin_username = var.jenkins_admin_username
  jenkins_admin_password = var.jenkins_admin_password
  github_user            = var.github_user
  github_pat             = var.github_pat

  providers = {
    kubernetes = kubernetes.eks
    helm = helm.eks
  }
}

# Підключаємо модуль Argo CD
module "argo_cd" {
  source          = "../modules/argo-cd"
  namespace       = "argocd"
  chart_version   = "5.46.4"
  github_user     = var.github_user
  github_pat      = var.github_pat
  github_repo_url = var.github_repo_url
  github_branch   = "final-project"
  django_app_dir  = "final-project/charts/django-app"

  providers = {
    helm = helm.eks
  }

  depends_on = [
    module.k8s-external-secrets
  ]
}

# Підключаємо модуль monitoring
module "monitoring" {
  source                    = "../modules/monitoring"
  namespace                 = "monitoring"
  grafana_admin_password    = var.grafana_admin_password
  enable_jenkins_monitoring = true
  enable_argocd_monitoring  = true

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  depends_on = [
    module.argo_cd,
    module.jenkins
  ]
}
