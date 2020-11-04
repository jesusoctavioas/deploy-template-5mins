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
variable "AWS_EC2_AMI" {}
variable "ENVIRONMENT_NAME" {}

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
}

// EC2 Instance

resource "aws_instance" "webapp" {
    ami = var.AWS_EC2_AMI
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.key_pair.key_name

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

resource "aws_db_instance" "postgres" {
    allocated_storage = 20
    engine = "postgres"
    instance_class = "db.t2.small"
    name = "db_${random_string.postgres_db.result}"
    username = "user_${random_string.postgres_username.result}"
    password = random_password.postgres_password.result
    skip_final_snapshot = true
    publicly_accessible = true

    tags = {
        "Source" = "Five Minute Production"
    }
}

output "public_ip" {
    value = aws_instance.webapp.public_ip
}

output "database_url" {
    value = "postgres://${aws_db_instance.postgres.username}:${aws_db_instance.postgres.password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.name}"
}

output "key_pair" {
    value = aws_key_pair.key_pair
}
