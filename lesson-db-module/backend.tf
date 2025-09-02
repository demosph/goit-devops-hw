terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.51"
    }
  }
  backend "s3" {
    bucket         = "goit-tfstate-bucket"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
