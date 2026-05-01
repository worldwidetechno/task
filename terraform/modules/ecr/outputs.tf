output "repository_url" {
  value       = aws_ecr_repository.api.repository_url
  description = "ECR repository URL for API docker push/pull"
}

output "repository_name" {
  value       = aws_ecr_repository.api.name
  description = "ECR repository name for API"
}

output "repository_arn" {
  value       = aws_ecr_repository.api.arn
  description = "ECR repository ARN for API"
}

output "app_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL for app docker push/pull"
}

output "app_repository_name" {
  value       = aws_ecr_repository.app.name
  description = "ECR repository name for app"
}

output "app_repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "ECR repository ARN for app"
}