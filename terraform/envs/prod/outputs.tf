output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name — used for kubectl context"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for API docker push/pull"
}

output "ecr_app_repository_url" {
  value       = module.ecr.app_repository_url
  description = "ECR repository URL for app docker push/pull"
}

output "api_pod_role_arn" {
  value       = module.eks.api_pod_role_arn
  description = "IRSA role ARN — annotate the api ServiceAccount with this"
}

output "alb_controller_role_arn" {
  value       = module.eks.alb_controller_role_arn
  description = "IRSA role ARN for the AWS Load Balancer Controller"
}

output "redis_primary_endpoint" {
  value       = module.redis.primary_endpoint
  description = "Redis primary endpoint for application connection"
}