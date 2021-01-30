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
  apply_immediately = true
  allocated_storage = var.PG_ALLOCATED_STORAGE
  engine = "postgres"
  instance_class = var.PG_INSTANCE_CLASS
  name = "db_${random_string.postgres_db.result}"
  username = "user_${random_string.postgres_username.result}"
  password = random_password.postgres_password.result
  skip_final_snapshot = true
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.security_group.id]
  db_subnet_group_name = aws_db_subnet_group.postgres_subnet.name

  tags = local.common_tags
}

# Output

output "database_url" {
  value = "postgres://${aws_db_instance.postgres.username}:${aws_db_instance.postgres
  .password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.name}"
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
