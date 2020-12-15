output "public_ip" {
  value = aws_eip.public_ip.public_ip
}

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
