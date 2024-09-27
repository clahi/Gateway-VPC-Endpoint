terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5"
    }
  }
  required_version = ">= 1.7"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# Creating local variables for the 6 subnets so that it can be reusable.
locals {
  public_subnets = {
    "subnet-A" = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1a", tag_name = "public_subnetA" }
    "subnet-B" = { cidr_block = "10.0.3.0/24", availability_zone = "us-east-1b", tag_name = "public_subnetB" }
    "subnet-C" = { cidr_block = "10.0.5.0/24", availability_zone = "us-east-1c", tag_name = "public_subnetC" }
  }

  private_subnets = {
    "subnet-A" = { cidr_block = "10.0.2.0/24", availability_zone = "us-east-1a", tag_name = "private_subnetA" }
    "subnet-B" = { cidr_block = "10.0.4.0/24", availability_zone = "us-east-1b", tag_name = "private_subnetB" }
    "subnet-C" = { cidr_block = "10.0.6.0/24", availability_zone = "us-east-1c", tag_name = "private_subnetC" }
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.tag_name
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main_vpc.id

  for_each          = local.private_subnets
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.tag_name
  }
}

# Internet gateway that is associated with the main vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "internet_gateway"
  }
}

# Route table with a route to the internet gateway for instances inside the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Association of the public route table to all the public subnets in the vpc
resource "aws_route_table_association" "public_route_table_association" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

# Creating a route table for each of the private subnets
resource "aws_route_table" "private_route_tables" {
  for_each = aws_subnet.private_subnets

  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${each.value.id}_private_route_table"
  }
}

# The VPC endpoint (Gateway endpoint) to used to connect to the S3 bucket instead of traversing the wider internet
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"

  tags = {
    Name = "s3_endpoint"
  }
}

# Associating the endpoint with all the route tables.
resource "aws_vpc_endpoint_route_table_association" "endpoint_route_table_associations_private_route_tables" {
  # Using for_each because we multiple private routables.
  for_each        = aws_route_table.private_route_tables
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = each.value.id

}

resource "aws_vpc_endpoint_route_table_association" "endpoint_route_table_associations_public_route_table" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = aws_route_table.public_route_table.id
}
