###### ROUTE TABLES ######

# Public Route Table for both public subnets 
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.ha_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ha_igw.id
  }

  tags = {
    Name = "public_subnet_rt"
  }
}


# Private Route Table for both private subnets
resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.ha_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ha_nat.id
  }

  tags = {
    Name = "private_subnet_rt"
  }
}



# Public Route Table Associations
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_subnet_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_subnet_rt.id
}