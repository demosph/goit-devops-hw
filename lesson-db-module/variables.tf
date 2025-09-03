variable "region" {
  description = "AWS region for deployment"
  default     = "us-east-2"
}

variable "github_user" {
  description = "GitHub username"
  type        = string
}

variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}
