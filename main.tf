terraform {
    backend "http" {}

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

locals {
    common_tags = {
        source = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

# AWS Config

provider "aws" {
}

# SSH Key Pair

resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "key_pair" {
    key_name = "${var.ENVIRONMENT_NAME}_KEY_PAIR"
    public_key = tls_private_key.private_key.public_key_openssh

    tags = local.common_tags
}

# EC2 Instance

data "aws_ami" "ubuntu_20_04" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    # Canonical
    owners = ["099720109477"]
}


resource "aws_security_group" "five_minute_public" {
    name = "five_minute_public_security_group_${var.ENVIRONMENT_NAME}"
    description = "Publicly accessible security group"

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = local.common_tags
}

resource "aws_instance" "webapp" {
    ami = data.aws_ami.ubuntu_20_04.id
    instance_type = var.EC2_INSTANCE_TYPE
    key_name = aws_key_pair.key_pair.key_name
    security_groups = [aws_security_group.five_minute_public.name]

    tags = local.common_tags
}

resource "aws_eip" "public_ip" {
    instance = aws_instance.webapp.id

    tags = local.common_tags
}

# RDS Postgres

resource "random_string" "postgres_db" {
    length = 12
    special = false
}

resource "random_string" "postgres_username" {
    length = 16
    special = false
}

resource "random_password" "postgres_password" {
    length = 20
    special = false
}

data "aws_vpc" "default" {
    default = true
}

resource "aws_security_group" "db_instance" {
    name = "${var.ENVIRONMENT_NAME}_DATABASE"
    vpc_id = data.aws_vpc.default.id

    tags = local.common_tags
}

resource "aws_security_group_rule" "allow_db_access" {
    type = "ingress"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_group_id = aws_security_group.db_instance.id
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_db_instance" "postgres" {
    apply_immediately = true
    allocated_storage = var.POSTGRES_ALLOCATED_STORAGE
    engine = "postgres"
    instance_class = var.POSTGRES_INSTANCE_CLASS
    name = "db_${random_string.postgres_db.result}"
    username = "user_${random_string.postgres_username.result}"
    password = random_password.postgres_password.result
    skip_final_snapshot = true
    publicly_accessible = true

    vpc_security_group_ids = [aws_security_group.db_instance.id]

    tags = local.common_tags
}

# S3 Bucket

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "s3-bucket-${var.SHORT_ENVIRONMENT_NAME}"
    acl = "public-read"
    force_destroy = true

    tags = local.common_tags
}
