variable "region" {
  description = "AWS region for deployment"
  default     = "us-east-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "example-eks-cluster"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the node group"
  default     = "example-node-group"
}

variable "instance_type" {
  description = "EC2 instance type for the worker nodes"
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "ebs_csi_driver_version" {
  description = "Version of aws-ebs-csi-driver addon (use aws console/CLI to see latest eksbuild)"
  type        = string
  default     = "v1.48.0-eksbuild.1"
}

variable "eks_pod_identity_agent_version" {
  description = "Version of eks-pod-identity-agent addon"
  type        = string
  default     = "v1.3.8-eksbuild.2"
}