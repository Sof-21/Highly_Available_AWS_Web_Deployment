##### SUBNETS #####


# Public subnets creation
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ha_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.ha_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "public_subnet_2"
  }
}


# Private subnets creation

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.ha_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.ha_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_2"
  }
}

