variable "project" {
  type        = string
  default     = "mindmeld"
  description = "Project name prefix for all resources"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy into"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the prod VPC"
}

variable "allowed_cidr" {
  type        = string
  description = "Your Jenkins server public IP in CIDR notation — restricts EKS API server access"
}

variable "redis_auth_token" {
  type        = string
  sensitive   = true
  description = "Strong password for Redis AUTH (min 16 chars) — set via TF_VAR_redis_auth_token"
}

variable "redis_node_type" {
  type        = string
  default     = "cache.t4g.small"
  description = "ElastiCache node type for prod"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "EKS Kubernetes version"
}

variable "node_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for EKS worker nodes"
}

variable "node_desired" {
  type        = number
  default     = 2
  description = "Desired number of EKS worker nodes"
}

variable "node_min" {
  type        = number
  default     = 2
  description = "Minimum number of EKS worker nodes"
}

variable "node_max" {
  type        = number
  default     = 6
  description = "Maximum number of EKS worker nodes"
}
