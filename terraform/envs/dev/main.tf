terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "mindmeld-terraform-state"
    key            = "mindmeld/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "mindmeld-terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${var.project}/dev/redis-auth-token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = var.redis_auth_token
}

module "vpc" {
  source       = "../../modules/networking"
  project      = var.project
  environment  = "dev"
  vpc_cidr     = var.vpc_cidr
  allowed_cidr = var.allowed_cidr
}

module "ecr" {
  source         = "../../modules/ecr"
  project        = var.project
  environment    = "dev"
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "redis" {
  source             = "../../modules/redis"
  project            = var.project
  environment        = "dev"
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_redis_id        = module.vpc.sg_redis_id
  node_type          = var.redis_node_type
  auth_token         = var.redis_auth_token
}

module "eks" {
  source                              = "../../modules/eks"
  project                             = var.project
  environment                         = "dev"
  aws_region                          = var.aws_region
  vpc_id                              = module.vpc.vpc_id
  public_subnet_ids                   = module.vpc.public_subnet_ids
  private_subnet_ids                  = module.vpc.private_subnet_ids
  sg_eks_cluster_id                   = module.vpc.sg_eks_cluster_id
  sg_eks_nodes_id                     = module.vpc.sg_eks_nodes_id
  redis_host                          = module.redis.primary_endpoint
  redis_port                          = module.redis.port
  redis_secret_arn                    = aws_secretsmanager_secret.redis_auth.arn
  kubernetes_version                  = var.kubernetes_version
  node_instance_type                  = var.node_instance_type
  node_desired                        = var.node_desired
  node_min                            = var.node_min
  node_max                            = var.node_max
  k8s_namespace                       = "mindmeld"
  cluster_endpoint_public_access_cidr = var.allowed_cidr
}