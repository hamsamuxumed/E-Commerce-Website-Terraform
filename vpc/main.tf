data "aws_availability_zones" "available" {
}

data "aws_region" "current" {
}

locals {
  az_cidrs = {
    az1 = cidrsubnet(var.vpc_cidr_block, 2, 0)
    az2 = cidrsubnet(var.vpc_cidr_block, 2, 1)
    az3 = cidrsubnet(var.vpc_cidr_block, 2, 2)
    az4 = cidrsubnet(var.vpc_cidr_block, 2, 3)
  }
}

##
# VPC
##

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge({
    "Name" = var.name
  }, var.tags)
}

##
# Subnets
##

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(local.az_cidrs["az${count.index + 1}"], 2, var.create_private_subnets ? 2 : 0)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags = merge({
    "Name"       = "${var.name}-public-${data.aws_availability_zones.available.names[count.index]}",
    "SubnetType" = "public"
  }, var.tags)
}

# private subnets
resource "aws_subnet" "private" {
  count             = var.create_private_subnets ? var.az_count : 0
  cidr_block        = cidrsubnet(local.az_cidrs["az${count.index + 1}"], 1, 0)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  tags = merge({
    "Name"       = "${var.name}-private-${data.aws_availability_zones.available.names[count.index]}",
    "SubnetType" = "private"
  }, var.tags)
}

##
# Enable VPC Flow Logs
##

resource "aws_flow_log" "flow_log" {
  count                = var.vpc_flow_logs_s3_bucket_name == "" ? 0 : 1
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::${var.vpc_flow_logs_s3_bucket_name}/${var.name}/vpc-flowlog/"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  tags = merge({
    "Name" = "${var.name}-vpc-flowlog"
  }, var.tags)
}

##
# Internet Gateway
##

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge({
    "Name" = "${var.name}-gw"
  }, var.tags)
}

##
# NAT
##

resource "aws_eip" "nat_gw" {
  count = var.create_private_nat_gateways && var.create_private_subnets ? var.az_count : 0
  domain = "vpc"

  tags = merge({
    "Name" = "${var.name}-eip-${data.aws_availability_zones.available.names[count.index]}"
  }, var.tags)
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.create_private_nat_gateways && var.create_private_subnets ? var.az_count : 0
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.nat_gw.*.id, count.index)

  tags = merge({
    "Name" = "${var.name}-nat-${data.aws_availability_zones.available.names[count.index]}"
  }, var.tags)
}

##
# Routing:
#  - For public, create route table for Internet Gateway
#  - For private, create a route table through AZ's NAT Gateway.
##

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    "Name" = "${var.name}-public"
  }, var.tags)
}

resource "aws_route_table" "private" {
  count  = var.create_private_subnets ? var.az_count : 0
  vpc_id = aws_vpc.main.id

  tags = merge({
    "Name" = "${var.name}-private-${data.aws_availability_zones.available.names[count.index]}"
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.create_private_subnets ? var.az_count : 0
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "private_nat_route" {
  count                  = var.create_private_nat_gateways && var.create_private_subnets ? var.az_count : 0
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw.*.id, count.index)
}

##
# VPC Endpoint gateways (S3 and DynamoDB are free because they are 'gateways'; 
# other endpoints of type 'Interface' cost money)
##

resource "aws_vpc_endpoint" "private-s3" {
  vpc_id = aws_vpc.main.id
  route_table_ids = concat(
    [aws_route_table.public.id],
  aws_route_table.private.*.id)
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  policy            = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
POLICY
}

resource "aws_vpc_endpoint" "private-dynamodb" {
  vpc_id = aws_vpc.main.id
  route_table_ids = concat(
    [aws_route_table.public.id],
  aws_route_table.private.*.id)
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  policy            = <<POLICY
{
  
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "dynamodb:*",
            "Resource": "arn:aws:dynamodb:*"
        }
    ]
}
POLICY
}
