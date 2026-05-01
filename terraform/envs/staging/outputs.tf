output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_app_repository_url" {
  value = module.ecr.app_repository_url
}

output "api_pod_role_arn" {
  value = module.eks.api_pod_role_arn
}

output "alb_controller_role_arn" {
  value = module.eks.alb_controller_role_arn
}

output "redis_primary_endpoint" {
  value = module.redis.primary_endpoint
}