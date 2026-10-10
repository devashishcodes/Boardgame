
# Get available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnet - AZ1
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.boardgame_vpc.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-az1"
    Project = var.project_name
  }
}

# Public Subnet - AZ2
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.boardgame_vpc.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-az2"
    Project = var.project_name
  }
}

# Private Subnet - AZ1
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.boardgame_vpc.id
  cidr_block        = var.private_subnet_az1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "${var.project_name}-private-az1"
    Project = var.project_name
  }
}

# Private Subnet - AZ2
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.boardgame_vpc.id
  cidr_block        = var.private_subnet_az2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name    = "${var.project_name}-private-az2"
    Project = var.project_name
  }
}
