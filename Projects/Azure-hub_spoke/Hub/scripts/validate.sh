#!/bin/bash

# Validation Script for Terraform Configuration
# This script validates the Terraform configuration files

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ENVIRONMENT_DIR="$PROJECT_ROOT/AU/Nonprod"

echo "==================================="
echo "Terraform Configuration Validation"
echo "==================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Display terraform version
echo "Terraform version:"
terraform version
echo ""

# Change to environment directory
cd "$ENVIRONMENT_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -upgrade
echo ""

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate
echo ""

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check -recursive "$PROJECT_ROOT/modules"
terraform fmt -check
echo ""

echo "==================================="
echo "Validation completed successfully!"
echo "==================================="
