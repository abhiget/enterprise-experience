# Hub-Spoke Azure Infrastructure

Hub and Spoke network architecture implementation for Azure using Terraform.

## Overview

This repository contains Terraform configurations for deploying a Hub-Spoke network topology in Azure. The Hub VNet serves as a central point of connectivity, while Spoke VNets connect through VNet peering.

## Directory Structure

- `docs/` - Documentation files
- `modules/` - Reusable Terraform modules
- `AU/` - Region-specific configurations
- `scripts/` - Automation scripts

## Prerequisites

- Terraform >= 1.0
- Azure CLI configured
- Appropriate Azure permissions

## Deployment

Refer to `docs/deployment-guide.md` for detailed deployment instructions.

## Architecture

See `docs/architecture.md` for architecture details.
