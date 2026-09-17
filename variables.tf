variable "region" {
  description = "The AWS region to deploy the infrastructure"
  default     = "us-east-1"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  default     = "t2.micro"
  type        = string
}

variable "ami" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-0e34b50e714a297f1" # Amazon Linux 2 AMI
  type        = string
}


# provide your admin IP in terraform.tfvars file or as a command line variable when running terraform apply
variable "admin_ip" {
  description = "The IP address of the admin user to manage the infrastructure"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_ip))
    error_message = "The admin_ip value must be a valid CIDR block, e.g., '93.159.26.201/32'."
  }
}

# node names
variable "node_name_a" {
  description = "The name of the node a"
  type        = string
}

variable "node_name_b" {
  description = "The name of the node b"
  type        = string
}