# DB instance

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

resource "aws_db_subnet_group" "postgres_subnet" {
  subnet_ids = [aws_subnet.subnet_primary.id, aws_subnet.subnet_secondary.id]
}

resource "aws_db_instance" "postgres" {
  count = var.DISABLE_POSTGRES == "true" ? 0 : 1
  apply_immediately = true
  allocated_storage = var.PG_ALLOCATED_STORAGE
  engine = "postgres"
  instance_class = var.PG_INSTANCE_CLASS
  name = "db_${random_string.postgres_db.result}"
  username = "user_${random_string.postgres_username.result}"
  password = random_password.postgres_password.result
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.security_group.id]
  db_subnet_group_name = aws_db_subnet_group.postgres_subnet.name

  tags = local.common_tags
}

# Output

output "database_url" {
  value = var.DISABLE_POSTGRES == "true" ? null : "postgres://${aws_db_instance.postgres[0].username}:${aws_db_instance.postgres[0]
  .password}@${aws_db_instance.postgres[0].endpoint}/${aws_db_instance.postgres[0].name}"
  sensitive = true
}

output "database_endpoint" {
  value = var.DISABLE_POSTGRES == "true" ? null : aws_db_instance.postgres[0].endpoint
  sensitive = true
}

output "database_address" {
  value = var.DISABLE_POSTGRES == "true" ? null : aws_db_instance.postgres[0].address
  sensitive = true
}

output "database_username" {
  value = var.DISABLE_POSTGRES == "true" ? null : aws_db_instance.postgres[0].username
  sensitive = true
}

output "database_password" {
  value = var.DISABLE_POSTGRES == "true" ? null : aws_db_instance.postgres[0].password
  sensitive = true
}

output "database_name" {
  value = var.DISABLE_POSTGRES == "true" ? null : aws_db_instance.postgres[0].name
  sensitive = true
}
