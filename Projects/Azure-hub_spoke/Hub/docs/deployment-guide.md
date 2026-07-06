# Deployment Guide

## Prerequisites

1. Azure subscription with appropriate permissions
2. Terraform installed (>= 1.0)
3. Azure CLI installed and authenticated

## Deployment Steps

### 1. Initialize Terraform

```bash
cd AU/Nonprod
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
```

Or use the provided script:

```bash
../../scripts/validate.sh
```

### 3. Plan Deployment

```bash
terraform plan -out=tfplan
```

Or use the provided script:

```bash
../../scripts/plan.sh
```

### 4. Apply Configuration

```bash
terraform apply tfplan
```

Or use the provided script:

```bash
../../scripts/apply.sh
```

## Configuration

Edit `AU/Nonprod/terraform.tfvars` to customize:
- Resource names
- VNet address spaces
- Subnet configurations
- Firewall rules
- Monitoring settings

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure Azure CLI is properly authenticated
2. **Permission Errors**: Verify your Azure role has necessary permissions
3. **State Lock**: Check for any ongoing operations or stale locks

## Rollback

To destroy all resources:

```bash
terraform destroy
```

## Support

For issues or questions, refer to the architecture documentation.
