variable "project" {
  type        = string
  description = "Project name used as a prefix for all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID for ECR repository policy"
}