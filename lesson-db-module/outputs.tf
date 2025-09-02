#-------------Backend-----------------

output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3_backend.dynamodb_table_name
}

#-------------VPC-----------------

output "vpc_id" {
  description = "ID створеної VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Список ID публічних підмереж"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Список ID приватних підмереж"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

#-------------ECR-----------------

output "ecr_repository_url" {
  description = "Повний URL ECR-репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN ECR-репозиторію"
  value       = module.ecr.repository_arn
}

output "ecr_repository_name" {
  description = "Ім'я ECR-репозиторію"
  value       = module.ecr.repository_name
}

#-------------EKS-----------------

output "eks_cluster_endpoint" {
  description = "EKS API endpoint для підключення до кластера"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Ім'я EKS кластера"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN для EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}

output "eks_addons" {
  description = "Встановлені EKS додатки"
  value       = module.eks.eks_addons
}

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

#-------------RDS-----------------

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}
