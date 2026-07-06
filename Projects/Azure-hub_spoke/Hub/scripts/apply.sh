#!/bin/bash

# Apply Script for Terraform Configuration
# This script applies the Terraform plan

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ENVIRONMENT_DIR="$PROJECT_ROOT/AU/Nonprod"
PLAN_FILE="$ENVIRONMENT_DIR/tfplan.out"

echo "==================================="
echo "Terraform Apply"
echo "==================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Check if plan file exists
if [ ! -f "$PLAN_FILE" ]; then
    echo "ERROR: Plan file not found at $PLAN_FILE"
    echo "Please run plan.sh first"
    exit 1
fi

# Change to environment directory
cd "$ENVIRONMENT_DIR"

# Confirm before applying
echo "WARNING: This will apply the Terraform configuration"
echo "Plan file: $PLAN_FILE"
echo ""
read -p "Do you want to continue? (yes/no): " -r REPLY
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Apply cancelled"
    exit 1
fi

# Apply the plan
echo "Applying Terraform configuration..."
terraform apply "$PLAN_FILE"
echo ""

echo "==================================="
echo "Apply completed successfully!"
echo "==================================="
