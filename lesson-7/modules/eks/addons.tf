data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM роль для EKS Pod Identity → EBS CSI Driver
resource "aws_iam_role" "ebs_csi_pod_identity_role" {
  name = "${var.cluster_name}-AmazonEBSCSIDriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEksAuthToAssumeRoleForPodIdentity"
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# Права для драйвера EBS CSI
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_pod_identity_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Add-on: EKS Pod Identity Agent (обов'язковий для Pod Identity)
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.eks_pod_identity_agent_version
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_cluster.eks]
}

# Add-on: Amazon EBS CSI Driver (із прив'язаною роллю Pod Identity)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_driver_version
  service_account_role_arn    = aws_iam_role.ebs_csi_pod_identity_role.arn
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    aws_eks_addon.pod_identity_agent
  ]
}

# Прив'язка (association) ролі до SA контролера драйвера
resource "aws_eks_pod_identity_association" "ebs_csi_controller" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_pod_identity_role.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.ebs_csi_driver
  ]
}

# Add-on: EKS Metrics Server
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eks]
}
