variable "project" {
  type        = string
  description = "Project name used as a prefix for all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from the vpc module"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the EKS cluster VPC config"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for EKS worker nodes"
}

variable "sg_eks_cluster_id" {
  type        = string
  description = "Security group ID for the EKS control plane"
}

variable "sg_eks_nodes_id" {
  type        = string
  description = "Security group ID for EKS worker nodes"
}

variable "redis_host" {
  type        = string
  description = "Redis primary endpoint hostname"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis port"
}

variable "redis_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for the Redis auth token"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "Kubernetes version for the EKS cluster"
}

variable "node_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for EKS worker nodes"
}

variable "node_desired" {
  type        = number
  default     = 2
  description = "Desired number of worker nodes"
}

variable "node_min" {
  type        = number
  default     = 2
  description = "Minimum number of worker nodes"
}

variable "node_max" {
  type        = number
  default     = 6
  description = "Maximum number of worker nodes"
}

variable "k8s_namespace" {
  type        = string
  default     = "mindmeld"
  description = "Kubernetes namespace for the application"
}

variable "cluster_endpoint_public_access_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach the EKS API server public endpoint"
}
