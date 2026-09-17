###### SECURITY GROUPS ######

# Jump Box Security Group
resource "aws_security_group" "bastalion_sg" {
  name        = "bastalion_sg"
  description = "ssh for admin from mac"
  vpc_id      = aws_vpc.ha_vpc.id

  # Inbound rule: allows ssh access from admin ip stored in terrafrom.tfvars file
  ingress {
    description = "ssh from anywhere for now"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  # outbound rule: to transfer all traffic to other instances
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastalion_sg"
  }
}


# Private EC2 Security Group

resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  description = "security group for private instances"
  vpc_id      = aws_vpc.ha_vpc.id

  # Inbound rules: to only accept traffic from the ALB
  ingress {
    description     = "http from alb"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound rule: allows ssh access from bastion host for admin access
  ingress {
    description     = "admin ssh from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastalion_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private_ec2_sg"
  }
}


# Application Load Balancer Security Group

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "loadbalancer security group to only allow http ingress traffic"
  vpc_id      = aws_vpc.ha_vpc.id

  # inbound rule: allows http traffic from the internet
  ingress {
    description = "Http traffic from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound rule: allows all outbound traffic to instances
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}