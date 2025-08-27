output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_ca" {
  description = "Base64 cluster CA"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = aws_iam_role.nodes.arn
}

output "ebs_csi_pod_identity_role_arn" {
  description = "IAM role used by the aws-ebs-csi-driver via EKS Pod Identity"
  value       = aws_iam_role.ebs_csi_pod_identity_role.arn
}

output "eks_addons" {
  description = "Installed EKS addons"
  value = {
    pod_identity_agent = try(aws_eks_addon.pod_identity_agent.addon_version, null)
    ebs_csi_driver     = try(aws_eks_addon.ebs_csi_driver.addon_version, null)
    metrics_server     = try(aws_eks_addon.metrics_server.addon_version, null)
  }
}
