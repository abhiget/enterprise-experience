# Hub-Spoke Network Architecture

## Overview

This document describes the Hub-Spoke network architecture implemented in this project.

## Architecture Components

### Hub VNet
- Central network hub for connectivity
- Contains Azure Firewall for traffic inspection
- Houses bastion host for secure access
- Implements routing through UDRs

### Spoke VNets
- Connected to Hub VNet via VNet peering
- Isolated workload networks
- Subject to Hub-managed security policies

### Security Components
- **Network Security Groups (NSGs)**: Enforce network access rules
- **Azure Firewall**: Centralized traffic inspection and filtering
- **Azure Bastion**: Secure RDP/SSH access without public IPs
- **User Defined Routes (UDRs)**: Custom routing policies

### Monitoring
- Log Analytics integration
- Network Watcher capabilities
- Performance monitoring

## Network Flow

All traffic from spokes to external networks flows through the Hub firewall for inspection and policy enforcement.
