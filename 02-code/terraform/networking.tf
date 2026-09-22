# VPC and Networking Configuration
# Creates a VPC with public and private subnets across 2 availability zones
# Public subnets: NAT Gateway
# Private subnets: ECS tasks (isolated from direct internet access)

resource "aws_vpc" "gateway" {
  tags = { Name = "gateway-vpc" }

  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true  # Required for ECS Service Connect
  enable_dns_support   = true
}

resource "aws_internet_gateway" "main" {
  tags   = { Name = "gateway" }
  vpc_id = aws_vpc.gateway.id
}

# Public Subnets - one per availability zone

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  tags = { Name = "public-${each.value}-subnet" }

  vpc_id                  = aws_vpc.gateway.id
  cidr_block              = cidrsubnet(aws_vpc.gateway.cidr_block, 8, index(local.azs, each.value))
  availability_zone       = each.value
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.gateway.id
  tags   = { Name = "public-route-table" }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private Subnets - one per availability zone
# ECS tasks run here for security (no direct internet access)

resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  tags = { Name = "private-${each.value}-subnet" }

  vpc_id            = aws_vpc.gateway.id
  cidr_block        = cidrsubnet(aws_vpc.gateway.cidr_block, 8, length(local.azs) + index(local.azs, each.value))
  availability_zone = each.value
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.gateway.id
  tags   = { Name = "private-route-table" }
}

# Route private subnet traffic through NAT Gateway for internet access
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.nat.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# NAT Gateway for private subnet outbound connectivity
# Allows ECS tasks to pull images from ECR and access AWS services

resource "aws_nat_gateway" "nat" {
  tags          = { Name = "nat" }
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public[element(sort(local.azs), 0)].id
}

resource "aws_eip" "elastic_ip" {
  tags   = { Name = "nat-elastic-ip" }
  domain = "vpc"
}


# ================================
# DATABASES - needed for RDS
# ================================


resource "aws_db_subnet_group" "db" {
  name       = "db-subnet-group"
  tags       = { Name = "database-subnet-group" }
  subnet_ids = [for s in aws_subnet.private : s.id]
}
