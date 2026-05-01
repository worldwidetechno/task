variable "project" {
  type        = string
  description = "Project name used as a prefix for all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed to reach the EKS API server public endpoint"
}
