provider "aws" {
  region = "us-east-2"
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
  }
}

# Дані кластера для конфігурації Kubernetes provider
data "aws_eks_cluster" "demo" {
  name = module.eks.eks_cluster_name
}

data "aws_eks_cluster_auth" "demo" {
  name = module.eks.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.demo.token
}