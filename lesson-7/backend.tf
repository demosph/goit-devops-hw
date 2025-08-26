terraform {
  backend "s3" {
    bucket         = "goit-tfstate-bucket"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
