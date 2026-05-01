variable "project" {
  type        = string
  description = "Project name used as a prefix for all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the ElastiCache subnet group"
}

variable "sg_redis_id" {
  type        = string
  description = "Security group ID for ElastiCache Redis"
}

variable "node_type" {
  type        = string
  default     = "cache.t4g.small"
  description = "ElastiCache node type"
}

variable "auth_token" {
  type        = string
  sensitive   = true
  description = "Redis AUTH token stored in Secrets Manager"
}
