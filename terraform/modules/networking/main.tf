locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  # Required tag for AWS Load Balancer Controller to discover public subnets
  tags = {
    Name                                                        = "${local.name_prefix}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb"                                    = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks-cluster"   = "shared"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Required tag for AWS Load Balancer Controller to discover private subnets
  tags = {
    Name                                                        = "${local.name_prefix}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"                          = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks-cluster"   = "shared"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${local.name_prefix}-nat-gw" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-public-rtb" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "${local.name_prefix}-private-rtb" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Security Groups ---

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB: allow HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-eks-cluster-sg"
  description = "EKS control plane: allow nodes and Jenkins to reach API server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Nodes to API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-eks-cluster-sg" }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${local.name_prefix}-eks-nodes-sg"
  description = "EKS worker nodes: inter-node, ALB to pods, control plane to kubelet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Inter-node communication (CNI)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description     = "ALB to pods"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description     = "Control plane to kubelet"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-eks-nodes-sg" }
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "ElastiCache Redis: allow only EKS nodes on 6379"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "EKS nodes to Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  tags = { Name = "${local.name_prefix}-redis-sg" }
}

data "aws_availability_zones" "available" {
  state = "available"
}
