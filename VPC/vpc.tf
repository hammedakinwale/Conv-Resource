terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# configuring vpc with cidr block
resource "aws_vpc" "web_vpc" {
  cidr_block            = var.vpc_cidr
  enable_dns_hostnames  = true

  tags = {
    Name = "web_VPC"
  }
}

# creating public subnet
resource "aws_subnet" "public_subnet" {
  cidr_block        = var.public_subnet_cidr
  vpc_id            = aws_vpc.web_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public_Subnet"
  }
}

# creating private subnet
resource "aws_subnet" "private_subnet" {
  cidr_block        = var.private_subnet_cidr
  vpc_id            = aws_vpc.web_vpc.id
  availability_zone = "us-east-1b"

  tags =  {
    Name = "Private_Subnet"
  }
}

# creating public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  tags =  {
    Name = "Public-Route_Table"
  }
}

# creating private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.web_vpc.id

  tags =  {
    Name = "Private_Route_Table"
  }
}

# associating public route table to public subnet
resource "aws_route_table_association" "public_subnet_association" {
  route_table_id  = aws_route_table.public_route_table.id
  subnet_id       = aws_subnet.public_subnet.id
}

# associating private route table to private subnet
resource "aws_route_table_association" "private_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  route_table_id  = aws_route_table.private_route_table.id
  subnet_id       = aws_subnet.private_subnet.id
}

# creating elastic ip
resource "aws_eip" "elastic_ip_for_nat_gw" {
  domain           = "vpc"
  associate_with_private_ip = "10.0.0.5"

  tags =  {
    Name = "web_EIP"
  }
}

# creating nat gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.elastic_ip_for_nat_gw.id
  subnet_id     = aws_subnet.public_subnet.id

  tags =  {
    Name = "web_NAT_GW"
  }
  depends_on = [aws_eip.elastic_ip_for_nat_gw]
}

# giving descret access to private resources 
resource "aws_route" "nat_gw_route" {
  route_table_id          = aws_route_table.private_route_table.id
  nat_gateway_id          = aws_nat_gateway.nat_gw.id
  destination_cidr_block  = "0.0.0.0/0"
}

# creating internet gateway
resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags =  {
    Name = "web_IGW"
  }
}

# giving internet access to public resources
resource "aws_route" "public_internet_gw_route" {
  route_table_id          = aws_route_table.public_route_table.id
  gateway_id              = aws_internet_gateway.web_igw.id
  destination_cidr_block  = "0.0.0.0/0"
}