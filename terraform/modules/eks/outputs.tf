output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster API server endpoint"
}

output "cluster_ca" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "EKS cluster certificate authority data"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.eks.arn
  description = "OIDC provider ARN for IRSA"
}

output "api_pod_role_arn" {
  value       = aws_iam_role.api_pod.arn
  description = "IAM role ARN for API pods (IRSA)"
}

output "alb_controller_role_arn" {
  value       = aws_iam_role.alb_controller.arn
  description = "IAM role ARN for AWS Load Balancer Controller (IRSA)"
}