# Mindmeld DevOps Solution

A production-ready Kubernetes API deployment on AWS with manual deployment workflow.

## Architecture

```
Internet ──HTTPS──▶ ALB ──▶ EKS Pods (Rust API)
                              │
                              ▼
                         ElastiCache Redis
                              │
                              ▼
                         ECR Repository
```

### Components

| Service | Purpose | Environment Sizing |
|---------|---------|-------------------|
| **EKS** | Kubernetes cluster for API pods | dev: 1 node, prod: 2-6 nodes |
| **ElastiCache** | Redis cache with replication | dev: t4g.micro, prod: t4g.small |
| **ECR** | Docker image registry | Immutable tags, scan on push |
| **ALB** | Load balancer (via Ingress) | Auto-provisioned by AWS LBC |

### Multi-Environment

- **dev**: `10.2.0.0/16` VPC, minimal sizing (1 node, t4g.micro Redis)
- **staging**: `10.1.0.0/16` VPC, mid sizing (1-3 nodes, t4g.micro Redis)
- **prod**: `10.0.0.0/16` VPC, full HA sizing (2-6 nodes, t4g.small Redis)

Each environment is completely isolated with separate:
- VPC and subnets across 2 AZs
- EKS cluster and Redis instance
- Shared ECR repository (cross-environment)
- Terraform state (shared S3 backend, different keys)

## Security Best Practices

### Network Security
- **Private subnets**: EKS nodes have no public IPs
- **Security groups**: Least privilege (ALB→pods:8080, pods→Redis:6379)
- **VPC isolation**: No cross-environment connectivity
- **EKS API**: Public access restricted to your IP only

### Secrets Management
- **No static credentials**: Pods use IRSA (IAM Roles for Service Accounts)
- **Redis AUTH**: Stored in AWS Secrets Manager, injected at runtime
- **ECR access**: Node IAM roles, no registry passwords

### Infrastructure Security
- **Immutable images**: ECR tags cannot be overwritten
- **Encrypted storage**: All EBS volumes use gp3 encryption
- **IMDSv2**: Enforced on all EKS nodes
- **Pod security**: `runAsNonRoot: true`, no privileged containers

### Operational Security
- **Terraform state**: Encrypted S3 backend with DynamoDB locking
- **Image scanning**: ECR scans all images on push
- **Audit logging**: EKS control plane logs to CloudWatch
- **Least privilege IAM**: Scoped roles for pods and nodes

## Deployment Guide

### 1. Prerequisites
```bash
# Install required tools
aws configure
terraform --version  # >= 1.6
kubectl version
helm version
docker --version
```

### 2. Bootstrap Terraform Backend
```bash
# Create S3 bucket and DynamoDB table for Terraform state
chmod +x scripts/s3-backend.sh
./scripts/s3-backend.sh
```

### 3. Deploy Infrastructure

Choose your environment (`dev`, `staging`, or `prod`):

```bash
cd terraform/envs/dev  # or staging/prod
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars - set allowed_cidr to your public IP
# Get your IP: curl -s https://checkip.amazonaws.com
```

Set the Redis password and deploy:
```bash
export TF_VAR_redis_auth_token="$(openssl rand -base64 32)"
terraform init
terraform plan
terraform apply
```

### 4. Configure EKS Access

```bash
# Connect kubectl to your cluster
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1

# Verify connection
kubectl get nodes
```

### 5. Install AWS Load Balancer Controller

```bash
# Get the ALB controller IAM role
ALB_ROLE=$(terraform output -raw alb_controller_role_arn)

# Install cert-manager (required dependency)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

# Add EKS Helm repo and install ALB controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=$ALB_ROLE"

# Wait for controller to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s
```

### 6. Build and Deploy API

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Build and push API image
docker build -t $ECR_URL:v1.0.0 api/
docker push $ECR_URL:v1.0.0

# Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/service-hpa.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Update deployment image
kubectl set image deployment/api api=$ECR_URL:v1.0.0 -n mindmeld

# Wait for deployment
kubectl rollout status deployment/api -n mindmeld --timeout=300s
```

### 7. Get API Endpoint

```bash
# Wait for ALB to be provisioned (1-2 minutes)
kubectl get ingress -n mindmeld -w

# Get the API URL
API_URL=$(kubectl get ingress api -n mindmeld -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "API available at: http://$API_URL"

# Test the API
curl -X POST http://$API_URL \
  -H "Content-Type: application/json" \
  -d '{"key":"test","value":"hello"}'

curl http://$API_URL/test
```

## Operations

### Health Monitoring
```bash
# Check cluster health
kubectl get nodes
kubectl get pods -n mindmeld
kubectl get hpa -n mindmeld

# Check application logs
kubectl logs -n mindmeld deployment/api --tail=50

# Check Redis connectivity
kubectl exec -n mindmeld deployment/api -- redis-cli -h $REDIS_HOST ping
```

### Scaling Operations
```bash
# Manual pod scaling
kubectl scale deployment api -n mindmeld --replicas=3

# Check HPA status (auto-scales on CPU > 70%)
kubectl describe hpa api -n mindmeld

# Scale EKS nodes (via Terraform)
terraform apply -var="node_desired=3"
```

### Application Updates
```bash
# Build new version
docker build -t $ECR_URL:v1.1.0 api/
docker push $ECR_URL:v1.1.0

# Rolling update
kubectl set image deployment/api api=$ECR_URL:v1.1.0 -n mindmeld

# Monitor rollout
kubectl rollout status deployment/api -n mindmeld
```

### Troubleshooting
```bash
# Pod issues
kubectl describe pod -n mindmeld -l app=api
kubectl logs -n mindmeld -l app=api --previous

# Ingress/ALB issues
kubectl describe ingress -n mindmeld api
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Network connectivity
kubectl exec -n mindmeld deployment/api -- nslookup $REDIS_HOST
kubectl exec -n mindmeld deployment/api -- curl -I http://localhost:8080
```

## Cost Optimization

- **EKS nodes**: t3.small for dev/staging, t3.medium for prod
- **Redis**: t4g.micro for dev/staging, t4g.small for prod  
- **ECR**: Lifecycle policy keeps only 10 recent images
- **EBS volumes**: gp3 with encryption
- **CloudWatch logs**: 30-day retention

## Repository Structure

```
├── api/                    # Rust API application
│   ├── src/main.rs        # API source code
│   ├── Cargo.toml         # Rust dependencies
│   └── Dockerfile         # Multi-stage Docker build
├── app/                    # React frontend (optional)
├── k8s/                    # Kubernetes manifests
│   ├── namespace.yaml     # mindmeld namespace
│   ├── serviceaccount.yaml # IRSA service account
│   ├── deployment.yaml    # API deployment
│   ├── service-hpa.yaml   # Service + HPA
│   └── ingress.yaml       # ALB ingress
├── scripts/
│   └── s3-backend.sh      # Terraform state bootstrap
├── terraform/
│   ├── modules/           # Reusable modules
│   │   ├── networking/    # VPC, subnets, security groups
│   │   ├── ecr/           # Docker image registry
│   │   ├── eks/           # EKS cluster, nodes, IRSA
│   │   └── redis/         # ElastiCache replication group
│   └── envs/              # Environment configs
│       ├── dev/           # Development environment
│       ├── staging/       # Staging environment
│       └── prod/          # Production environment
└── README.md
```

## Environment Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace mindmeld

# Destroy infrastructure
terraform destroy

# Clean up ECR images (optional)
aws ecr list-images --repository-name mindmeld/api --query 'imageIds[*]' --output text | \
  xargs -I {} aws ecr batch-delete-image --repository-name mindmeld/api --image-ids imageDigest={}
```