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

resource "aws_instance" "webapp" {
  ami = data.aws_ami.ubuntu_20_04.id
  instance_type = var.EC2_INSTANCE_TYPE
  key_name = aws_key_pair.key_pair.key_name

  vpc_security_group_ids = [aws_security_group.Five_Minute_Security_Group.id]
  subnet_id = aws_subnet.Five_Minute_Subnet.id

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
