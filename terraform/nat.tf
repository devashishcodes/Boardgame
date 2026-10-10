
# Elastic IP for NAT Gateway AZ1
resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-nat-eip-az1"
    Project = var.project_name
  }
}

# NAT Gateway in Public Subnet AZ1
resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name    = "${var.project_name}-nat-az1"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.igw]
}

# Elastic IP for NAT Gateway AZ2
resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name    = "${var.project_name}-nat-eip-az2"
    Project = var.project_name
  }
}

# NAT Gateway in Public Subnet AZ2
resource "aws_nat_gateway" "nat_az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  tags = {
    Name    = "${var.project_name}-nat-az2"
    Project = var.project_name
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private Route Table AZ1
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.boardgame_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az1.id
  }

  tags = {
    Name    = "${var.project_name}-private-rt-az1"
    Project = var.project_name
  }
}

# Private Route Table AZ2
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.boardgame_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az2.id
  }

  tags = {
    Name    = "${var.project_name}-private-rt-az2"
    Project = var.project_name
  }
}

# Associate Private AZ1 Subnet
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_az1.id
}

# Associate Private AZ2 Subnet
resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_az2.id
}
