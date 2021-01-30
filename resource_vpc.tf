resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = local.common_tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet_primary" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = local.common_tags
}

resource "aws_subnet" "subnet_secondary" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = local.common_tags
}

resource "aws_security_group" "security_group" {
  name = var.SHORT_ENVIRONMENT_NAME
  description = var.ENVIRONMENT_NAME
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "ssh"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
  }

  ingress {
    description = "http"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port = 80
  }

  ingress {
    description = "https"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
  }

  ingress {
    description = "postgres"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    to_port = 5432
  }

  ingress {
    description = "redis"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 6379
    to_port = 6379
  }

  egress {
    description = "all outgoing"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }

  tags = local.common_tags
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = local.common_tags
}

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = local.common_tags
}
