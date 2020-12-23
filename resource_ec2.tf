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

# ElasticIP

resource "aws_eip" "public_ip" {
  instance = aws_instance.webapp.id

  tags = local.common_tags
}

# Output

output "public_ip" {
  value = aws_eip.public_ip.public_ip
}

output "private_key" {
  value = tls_private_key.private_key
  sensitive = true
}
