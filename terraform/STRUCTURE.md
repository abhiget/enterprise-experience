# Terraform Project Structure

This repository follows a **provider-based hybrid architecture** designed for multi-cloud infrastructure management and demonstration of enterprise-grade IaC practices.

## Directory Layout

```
terraform/
├── modules/                           # Reusable cloud provider modules
│   ├── azure/                         # Azure-specific modules
│   │   ├── compute/                   # VM, AKS, App Service modules
│   │   ├── networking/                # VNet, Subnets, NLB modules
│   │   └── security/                  # NSG, KeyVault, RBAC modules
│   └── aws/                           # AWS-specific modules (future expansion)
│       ├── compute/                   # EC2, ECS, EKS modules
│       ├── networking/                # VPC, Subnets, ALB modules
│       └── security/                  # SG, IAM, KMS modules
│
├── deployments/                       # Concrete deployment implementations
│   ├── azure/                         # Azure production deployments
│   │   ├── hub-spoke-network/         # Hub-and-spoke network topology
│   │   ├── aks-platform-gitops/       # AKS cluster with GitOps
│   │   └── landing-zone/              # Azure Landing Zone pattern
│   └── aws/                           # AWS production deployments
│       ├── eks-cluster/               # EKS cluster deployment
│       └── vpc-setup/                 # VPC networking setup
│
└── docs/
    └── architecture/                  # Architecture diagrams and documentation
```

## Design Principles

### 1. **Provider Isolation**
- Each cloud provider has its own module directory
- Allows independent versioning and maintenance
- Enables multi-cloud strategy without tight coupling

### 2. **Separation of Concerns**
- **Modules**: Reusable, composable building blocks
- **Deployments**: Concrete implementations combining modules
- Clear dependency hierarchy

### 3. **Scalability**
- Easy to add new cloud providers (GCP, etc.)
- Modular approach prevents monolithic configurations
- Supports team scaling and ownership models

### 4. **Resume/Portfolio Value**
- Demonstrates enterprise IaC best practices
- Shows proficiency across multiple cloud providers
- Clean, professional repository structure

## Module Organization

### Azure Modules

#### compute/
- AKS (Azure Kubernetes Service)
- Virtual Machines
- App Service Plans
- Container Instances

#### networking/
- Virtual Networks
- Subnets & Route Tables
- Network Load Balancer
- Application Gateway

#### security/
- Network Security Groups
- Azure Key Vault
- Role-Based Access Control (RBAC)
- Policies & Compliance

### AWS Modules

#### compute/
- EC2 Instances
- ECS (Elastic Container Service)
- EKS (Elastic Kubernetes Service)
- Lambda Functions

#### networking/
- VPC & Subnets
- Application/Network Load Balancer
- CloudFront Distribution
- Route 53 Hosted Zones

#### security/
- Security Groups
- IAM Policies & Roles
- KMS Keys
- Secrets Manager

## Deployment Examples

### Azure Hub-Spoke Network
Complete implementation of hub-and-spoke topology using Azure networking modules.

### AKS Platform GitOps
Production-grade AKS cluster with GitOps integration (ArgoCD/Flux).

### AWS EKS Cluster
Complete EKS setup with networking, security, and managed node groups.

## Getting Started

1. Navigate to a specific deployment:
   ```bash
   cd terraform/deployments/azure/hub-spoke-network
   ```

2. Review the module references and variables:
   ```bash
   cat main.tf
   ```

3. Initialize and plan:
   ```bash
   terraform init
   terraform plan
   ```

## Best Practices Implemented

- ✅ Provider-specific module isolation
- ✅ Clear separation between modules and deployments
- ✅ Consistent naming conventions
- ✅ Scalable architecture for multi-cloud
- ✅ Documentation at each level
- ✅ Support for team collaboration and ownership

---

*This structure is optimized for portfolio demonstration and enterprise-ready IaC management.*
