variable "region" {
  description = "AWS region for deployment"
  default     = "us-east-2"
}

variable "github_user" {
  description = "GitHub username"
  type        = string
  default     = "demosph"
}

variable "github_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
  default     = "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"
}
