##### VPC #####

resource "aws_vpc" "ha_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ha_vpc"
  }
}



# Internet Gateway
resource "aws_internet_gateway" "ha_igw" {
  vpc_id = aws_vpc.ha_vpc.id

  tags = {
    Name = "ha_igw"
  }
}


# Elastic IP & NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.ha_igw]

  tags = {
    Name = "ha_nat_eip"
  }
}

resource "aws_nat_gateway" "ha_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "ha_nat"
  }

  depends_on = [aws_internet_gateway.ha_igw]
}