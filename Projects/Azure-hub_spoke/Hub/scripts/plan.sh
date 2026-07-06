#!/bin/bash

# Plan Script for Terraform Configuration
# This script generates a Terraform plan for review

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
ENVIRONMENT_DIR="$PROJECT_ROOT/AU/Nonprod"
PLAN_FILE="$ENVIRONMENT_DIR/tfplan.out"

echo "==================================="
echo "Terraform Plan Generation"
echo "==================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    exit 1
fi

# Change to environment directory
cd "$ENVIRONMENT_DIR"

# Initialize Terraform if needed
echo "Initializing Terraform..."
terraform init -upgrade
echo ""

# Generate plan
echo "Generating Terraform plan..."
terraform plan -out="$PLAN_FILE"
echo ""

echo "==================================="
echo "Plan saved to: $PLAN_FILE"
echo "Review the plan before applying"
echo "==================================="
