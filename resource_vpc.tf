resource "aws_vpc" "Five_Minute_VPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Five_Minute_VPC"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "Five_Minute_Subnet" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "Five_Minute_VPC_Subnet"
  }
}

resource "aws_subnet" "Five_Minute_Subnet_Secondary" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "Five_Minute_VPC_Subnet"
  }
}

resource "aws_security_group" "Five_Minute_Security_Group" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  name = "Five_Minute_VPC_Security_Group"
  description = "Five_Minute_VPC_Security_Group"

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

  egress {
    description = "all outgoing"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }

  tags = {
    Name = "Five_Minute_VPC_Security_Group"
    Description = "Five_Minute_VPC_Security_Group"
  }
}

resource "aws_network_acl" "Five_Minute_Security_Access_Control_List" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  subnet_ids = [aws_subnet.Five_Minute_Subnet.id]

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  ingress {
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  ingress {
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  tags = {
    Name = "Five_Minute_VPC_Access_Control_List"
  }
}

resource "aws_internet_gateway" "Five_Minute_Internet_Gateway" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  tags = {
    Name = "Five_Minute_VPC_Internet_Gateway"
  }
}

resource "aws_route_table" "Five_Minute_Route_Table" {
  vpc_id = aws_vpc.Five_Minute_VPC.id
  tags = {
    Name = "My VPC Route Table"
  }
}

resource "aws_route" "Five_Minute_Internet_Access" {
  route_table_id = aws_route_table.Five_Minute_Route_Table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.Five_Minute_Internet_Gateway.id
}

resource "aws_route_table_association" "Five_Minute_Association" {
  subnet_id = aws_subnet.Five_Minute_Subnet.id
  route_table_id = aws_route_table.Five_Minute_Route_Table.id
}
