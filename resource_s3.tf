# S3 Bucket

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "s3-bucket-${var.SHORT_ENVIRONMENT_NAME}"
  acl = "public-read"
  force_destroy = true

  tags = local.common_tags
}

# Output

output "s3_bucket" {
  value = aws_s3_bucket.s3_bucket.bucket
}

output "s3_bucket_domain" {
  value = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "s3_bucket_regional_domain" {
  value = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
}
