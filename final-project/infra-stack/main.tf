# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "../modules/s3-backend"
  bucket_name = "goit-tfstate-bucket"
  table_name  = "terraform-locks"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "../modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_name           = "goit-hw-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "../modules/ecr"
  ecr_name     = "django-app"
  scan_on_push = true
}

# Підключаємо модуль EKS
module "eks" {
  source        = "../modules/eks"
  cluster_name  = "eks-cluster-demo"        # Назва кластера
  subnet_ids    = module.vpc.public_subnets # ID підмереж
  instance_type = "t3.small"                # Тип інстансів
  region        = var.region                # Регіон
  desired_size  = 5                         # Бажана кількість нодів
  max_size      = 10                         # Максимальна кількість нодів
  min_size      = 5                         # Мінімальна кількість нодів

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}

# Підключаємо модуль k8s-baseline
module "k8s_baseline" {
  source = "../modules/k8s-baseline"

  providers = {
    kubernetes = kubernetes.eks
  }

  depends_on = [
    module.eks
  ]
}

# Підключаємо модуль RDS
module "rds" {
  source = "../modules/rds"

  name                  = "django-db"
  use_aurora            = false
  aurora_instance_count = 2

  # --- Aurora-only ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"

  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  # Common
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "django_db"
  username                = "django_user"
  password                = "pass9764gd"
  subnet_private_ids      = module.vpc.private_subnets
  subnet_public_ids       = module.vpc.public_subnets
  skip_final_snapshot     = true
  publicly_accessible     = true
  vpc_id                  = module.vpc.vpc_id
  multi_az                = true
  backup_retention_period = 7

  parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  tags = {
    Environment = "dev"
    Project     = "django-app"
  }
}
