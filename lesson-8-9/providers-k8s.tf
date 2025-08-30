# Дані кластера для конфігурації Kubernetes provider
data "aws_eks_cluster_auth" "demo" {
  name = module.eks.eks_cluster_name
  depends_on = [
    module.eks
  ]
}

provider "kubernetes" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.eks_cluster_ca)
  token                  = data.aws_eks_cluster_auth.demo.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.eks_cluster_ca)
    token                  = data.aws_eks_cluster_auth.demo.token
  }
}