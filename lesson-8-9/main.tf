# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "goit-tfstate-bucket"
  table_name  = "terraform-locks"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_name           = "lesson-7-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "django-app"
  scan_on_push = true
}

# Підключаємо модуль EKS
module "eks" {
  source        = "./modules/eks"
  cluster_name  = "eks-cluster-demo"        # Назва кластера
  subnet_ids    = module.vpc.public_subnets # ID підмереж
  instance_type = "t3.small"                # Тип інстансів
  region        = "us-east-2"               # Регіон
  desired_size  = 2                         # Бажана кількість нодів
  max_size      = 4                         # Максимальна кількість нодів
  min_size      = 2                         # Мінімальна кількість нодів
}

# Підключаємо модуль k8s-baseline
module "k8s_baseline" {
  source = "./modules/k8s-baseline"

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    module.eks
  ]
}

# Підключаємо модуль Jenkins
module "jenkins" {
  source            = "./modules/jenkins"
  cluster_name      = module.eks.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  providers = {
    helm = helm
  }

  depends_on = [
    module.eks
  ]
}
