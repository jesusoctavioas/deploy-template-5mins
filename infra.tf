terraform {
    backend "http" {}

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

// Environment variables

variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {}
variable "ENVIRONMENT_NAME" {}
variable "SHORT_ENVIRONMENT_NAME" {}
variable "POSTGRES_ALLOCATED_STORAGE" {
    default = 20
    type = number
}
variable "POSTGRES_INSTANCE_CLASS" {
    default = "db.t2.micro"
    type = string
}
variable "EC2_INSTANCE_TYPE" {
    default = "t2.micro"
    type = string
}

// AWS Config

provider "aws" {
    region = var.AWS_REGION
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
}

// SSH Key Pair

resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "key_pair" {
    key_name = "${var.ENVIRONMENT_NAME}_KEY_PAIR"
    public_key = tls_private_key.private_key.public_key_openssh

    tags = {
        "Source" = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

// EC2 Instance

data "aws_ami" "amazon_linux" {
    most_recent = true

    filter {
        name = "name"
        values = [
            "amzn2-ami-hvm*"]
    }

    owners = [
        "amazon"]
}

resource "aws_security_group" "five_minute_public" {
    name = "five_minute_public_security_group_${var.ENVIRONMENT_NAME}"
    description = "Publicly accessible security group"

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [
            "0.0.0.0/0"]
    }

    tags = {
        "Source" = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

resource "aws_instance" "webapp" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.EC2_INSTANCE_TYPE
    associate_public_ip_address = true
    key_name = aws_key_pair.key_pair.key_name
    security_groups = [
        aws_security_group.five_minute_public.name]

    tags = {
        "Source" = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

// RDS Postgres

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
}

resource "aws_security_group_rule" "allow_db_access" {
    type = "ingress"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_group_id = aws_security_group.db_instance.id
    cidr_blocks = [
        "0.0.0.0/0"]
}

resource "aws_db_instance" "postgres" {
    allocated_storage = var.POSTGRES_ALLOCATED_STORAGE
    engine = "postgres"
    instance_class = var.POSTGRES_INSTANCE_CLASS
    name = "db_${random_string.postgres_db.result}"
    username = "user_${random_string.postgres_username.result}"
    password = random_password.postgres_password.result
    skip_final_snapshot = true
    publicly_accessible = true

    vpc_security_group_ids = [
        aws_security_group.db_instance.id]

    tags = {
        "Source" = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

// S3 Bucket

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "s3-bucket-${var.SHORT_ENVIRONMENT_NAME}"
    acl = "public-read"

    tags = {
        "Source" = "Five Minute Production - ${var.ENVIRONMENT_NAME}"
    }
}

// TODO Provide SES     Email service
// TODO Provide SNS     Push notification
// TODO Provide SQS     Message queue

// Output

output "public_ip" {
    value = aws_instance.webapp.public_ip
}

output "database_url" {
    value = "postgres://${aws_db_instance.postgres.username}:${aws_db_instance.postgres.password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.name}"
    sensitive = true
}

output "database_endpoint" {
    value = aws_db_instance.postgres.endpoint
    sensitive = true
}

output "database_username" {
    value = aws_db_instance.postgres.username
    sensitive = true
}

output "database_password" {
    value = aws_db_instance.postgres.password
    sensitive = true
}

output "database_name" {
    value = aws_db_instance.postgres.name
    sensitive = true
}

output "private_key" {
    value = tls_private_key.private_key
    sensitive = true
}

output "s3_bucket" {
    value = aws_s3_bucket.s3_bucket.bucket
}

output "s3_bucket_domain" {
    value = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "s3_bucket_regional_domain" {
    value = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
}
