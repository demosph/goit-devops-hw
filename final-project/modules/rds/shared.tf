# Subnet group (used by both)
resource "aws_db_subnet_group" "default" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids
  tags       = var.tags
}

# Security group (used by both)
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # або змінна
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "pg_host" {
  name  = "/apps/django/postgres/host"
  type  = "String"
  value = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].endpoint
}

resource "aws_ssm_parameter" "pg_user" {
  name  = "/apps/django/postgres/username"
  type  = "String"
  value = var.username
}

resource "aws_ssm_parameter" "pg_pwd" {
  name  = "/apps/django/postgres/password"
  type  = "String"
  value = var.password
}
