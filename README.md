# Highly Available AWS Web Application

## Overview

## Architecture

[architecture diagram]

## Architecture Decisions

### VPC
### Public and Private Subnets
### Application Load Balancer
### EC2
### NAT Gateway
### Bastion Host
### Security Groups

## Traffic Flow

Internet → ALB → EC2

## Administrative Access

Laptop → Bastion → Private EC2

## Infrastructure

Terraform

## Deployment

terraform init
terraform plan
terraform apply

## Validation

- ALB returns HTTP 200
- Both EC2 targets report Healthy
- WebServer-A returns Server A page
- WebServer-B returns Server B page
- Private EC2s have no public IP
- SSH access is restricted

## Security Considerations

## Cost Considerations

## Cleanup

terraform destroy