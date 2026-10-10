# Highly Available AWS Web Application

## Overview
This project demonstrates a highly available AWS web application deployed using Terraform. The application runs on two EC2 instances distributed across multiple Availability Zones and placed in private subnets. An internet-facing Application Load Balancer distributes HTTP traffic across the healthy instances.

The project focuses on network segmentation, high availability, controlled administrative access, infrastructure as code, and repeatable infrastructure deployment using industry standard tools.

Git is used as the source of truth for the infrastructure code, while Terraform is used to provision and manage the AWS environment.

## Technologies

- AWS VPC
- EC2
- Application Load Balancer
- NAT Gateway
- Internet Gateway
- Security Groups
- Terraform
- Nginx
- Git
- GitHub Actions
- Open Id Connect


## Architecture

![AWS architecture diagram](Image/ha_vpc.png)
The architecture separates public-facing components from the private application tier while distributing the web servers across multiple Availability Zones.

## Architecture Decisions

### VPC
A dedicated VPC provides an isolated networking environment for the application. It defines the IP address space, subnets, routing, and network boundaries used by the infrastructure.

### Public and Private Subnets
Public subnets host the internet-facing Application Load Balancer, NAT Gateway, and bastion host.

Private subnets host the two EC2 web servers, with each instance deployed in a separate Availability Zone.

This separation prevents the backend instances from being directly reachable from the internet while allowing them to initiate outbound connections through the NAT Gateway.

### Application Load Balancer

An internet-facing Application Load Balancer is deployed across multiple Availability Zones. It receives HTTP traffic from the internet and forwards requests to healthy EC2 instances in the private subnets.

The ALB provides a single public entry point while keeping the backend instances inaccessible directly from the internet.

### EC2

Two EC2 instances are deployed in separate private subnets across two Availability Zones. Each instance runs Nginx and serves HTTP traffic on port 80.

Each server displays its node identity, allowing the ALB's traffic distribution to be observed during testing.

### NAT Gateway

A NAT Gateway is deployed in a public subnet to provide outbound internet connectivity for resources in the private subnets.

The private EC2 instances can use the NAT Gateway to reach external services for activities such as package updates, while remaining inaccessible to unsolicited inbound internet traffic.

### Bastion Host

A bastion host is deployed in a public subnet to provide controlled administrative SSH access to the private EC2 instances.

SSH access to the bastion is restricted to the administrator's public IP address. The private EC2 instances do not require public IP addresses or direct internet-facing SSH access.

The bastion can be removed when administrative access is no longer required.

### Security Groups

Separate security groups are used for the ALB, bastion host, and private EC2 instances.

Traffic is restricted between each layer:
```
Internet     → ALB          : HTTP 80
Admin        → Bastion      : SSH 22
Bastion      → Private EC2  : SSH 22
ALB          → Private EC2  : HTTP 80
```

## Traffic Flow

### Application Traffic

```text
Internet
   ↓
Internet Gateway
   ↓
Application Load Balancer
   ↓
Target Group
   ↓
Private EC2 instances
   ↓
Nginx :80
```
### Private Instance Outbound Traffic
```
Private EC2
   ↓
Private Route Table
   ↓
NAT Gateway
   ↓
Internet Gateway
   ↓
Internet
```
### Adminstrative Traffic
```
Administrator Laptop
   ↓ SSH :22
Bastion Host
   ↓ SSH :22
Private EC2
```
## Infrastructure

```
terraform/
├-- provider.tf
|-- Alb_and_targets.tf
├-- keypairs.tf
├-- vpc.tf
├-- subnets.tf
├-- route_tables.tf
├-- security_groups.tf
├-- instances.tf
├-- alb.tf
├-- variables.tf
├-- outputs.tf
└── user_data.sh.tpl
```
The infrastructure is defined using Terraform, allowing the entire environment to be created and managed as code.

Terraform variables make the configuration reusable across environments, while outputs expose useful information such as the ALB DNS name and bastion public IP.

```
Note: Environment-specific variable values are not included in the repository. They can be provided through `terraform.tfvars` or supplied at runtime when executing Terraform commands.
```


## Deployment

### Prerequisites

- AWS account
- AWS CLI configured with appropriate credentials
- Terraform installed
- SSH key pairs generated via `keypairGenerator.sh`
- Administrator public IP address configured as a Terraform variable

### Terraform Deployment
To initialize terraform

```
terraform init
```
To format and validate the terraform module syntax
```
terraform fmt
terraform validate
```
To plan and deploy the infrastructure
```
terraform plan
terraform apply
```
## Validation

### ALB Target Group

![ALB target group showing both instances healthy](Image/alb-targets-healthy.png)

Both EC2 instances are registered with the ALB target group and report a healthy status.

### Application Served Through the ALB

![Application served through ALB](Image/alb-response.png)

The application is accessible through the ALB DNS name.

### Private EC2 Instances

![Private EC2 instances](Image/private-ec2.png)

Both EC2 instances are deployed without public IP addresses.

### Terraform Deployed
![Terraform outputs](Image/terraform-outputs.png)

## Security Considerations

### Network isolation

Backend EC2 instances are located in private subnets and do not have public IP addresses. They are not directly reachable from the public internet.

### Restricted SSH

SSH access to the bastion is restricted to the administrator's public IP address, reducing its exposure to unauthorized SSH connections from the internet.

### Security-group-based access

Backend instances only accept HTTP traffic from the ALB and SSH traffic from the bastion.

### Least exposure

The ALB is the public application entry point, while backend infrastructure remains private.

## Limitations

This project is intentionally designed as a learning/demo environment rather than a production deployment.

Current limitations include:

- HTTP is used instead of HTTPS/TLS.
- The ALB is accessed through its AWS DNS name rather than a custom domain.
- Centralized logging and monitoring have not been implemented.
- The NAT architecture uses a single NAT Gateway, which introduces an AZ-level dependency.
- The bastion host is used for administrative access rather than a managed access solution.
- The EC2 instances are statically provisioned and are not managed by an Auto Scaling Group. If an instance fails, it will not be automatically replaced.
- Terraform s3 backend is not configured with s3 versioning due to this project being a demo

### Production Enhancements
For a production environment, potential enhancements would include:

- HTTPS/TLS termination at the ALB using ACM
- Custom domain name using Route 53
- Multi-AZ NAT Gateways to remove the single-NAT dependency
- Centralized logging and monitoring
- Automated patch management
- Additional observability and alerting
- Deploy the application tier using an Auto Scaling Group with a Launch Template and configurable scaling policies.
- Managed administrative access using AWS Systems Manager Session Manager
- Enable S3 bucket versioning for the Terraform state backend to retain previous state versions, allowing recovery from accidental overwrites or state corruption. Configure appropriate lifecycle policies to manage storage costs and retention.

 ### CI/CD deployment
**Important**: The `GithubActionsTerraformRole` must be created and configured in AWS before running the GitHub Actions deployment workflow. The role can be created through the AWS Console or AWS CLI.

The workflow uses OpenID Connect (OIDC) federation to authenticate to AWS without storing long-lived AWS access keys in GitHub Secrets. GitHub acts as the OIDC identity provider and issues a short-lived JSON Web Token (JWT) to the workflow. The JWT is then presented to AWS STS using `AssumeRoleWithWebIdentity`, where AWS validates the token against the configured GitHub OIDC provider and, if the trust policy conditions are satisfied, issues temporary AWS credentials for the IAM role.

The workflow uses `sts.amazonaws.com` as the OIDC token audience (aud). The IAM role trust policy also restricts access to the specific GitHub repo and environment using the `sub` claim. AWS supports subject/sub as a GitHub Actions OIDC trust condition, allowing the role to be scoped to a specific repo and environment.

The IAM role is configured with a 1-hour maximum session duration. The credentials issued to a workflow run are temporary and expire when the session ends. A subsequent workflow run must authenticate through GitHub OIDC and assume the role again to obtain a new set of temporary credentials.

**Note:** GitHub introduced immutable OIDC claims for repositories created after *July 15, 2026*. For these repositories, the IAM role trust policy must explicitly reference the repository and owner IDs in the `token.actions.githubusercontent.com:sub` condition.

You can retrieve the repository and owner IDs using the GitHub API:
```
curl -s https://api.github.com/repos/<username>/<repo_name> | grep -E '"id":|"login":'
```

The GitHub Actions workflow uses an AWS IAM role with a federated principal referencing the GitHub OIDC provider configured under IAM → Identity providers.

Example trust policy:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": [
                "sts:AssumeRoleWithWebIdentity",
                "sts:TagSession"
            ],
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:Sof-21@<Owner_id>/Highly_Available_AWS_Web_Deployment@<repo_id>:environment:production"
                }
            }
        }
    ]
}
```
The sub condition restricts role assumption to GitHub Actions running from the specified repository and production environment.

This prevents other repositories from using the same IAM role, even if they have access to the GitHub OIDC provider.

#### IAM Permissions and Access Control

The GithubActionsTerraformRole uses an attached IAM permissions policy to authorize Terraform operations against AWS resources.

The policy grants the permissions required to:

**EC2 and VPC:** Create, modify, describe, and delete the networking resources and EC2 instances required by the deployment.

**Elastic Load Balancing:** Create and manage the Application Load Balancer, listeners, target groups, and target registrations.

**Terraform State (Amazon S3):** List the state bucket and read, write, and delete objects under the highly-available-web-deployment/ prefix.

**State Locking:** Access the S3 lockfile required for native Terraform state locking.

#### Terraform State Management
 Terraform uses an Amazon S3 remote backend to store persistent state, with native S3 state locking enabled to prevent concurrent operations from modifying the state simultaneously. This allows separate GitHub Actions deployment and destroy workflows to access the same state, enabling safe and consistent infrastructure lifecycle management.

**Security and Reliability:** The S3 backend uses restricted IAM permissions and bucket access policies to control access to the state file.

## Cost Considerations

The architecture includes AWS resources that can incur charges, including:

- Application Load Balancer
- NAT Gateway
- EC2 instances
- Elastic IP addresses
- Data transfer

As this is a learning/demo environment, the infrastructure should be destroyed when it is not being used to avoid unnecessary AWS costs.

## Cleanup
Terraform can be used to remove the infrastructure when the environment is no longer required, helping avoid unnecessary AWS charges.
```
terraform destroy
```
Alternatively, trigger the pre-configured `terraform-destroy` GitHub Actions workflow to remove the Terraform-managed infrastructure.