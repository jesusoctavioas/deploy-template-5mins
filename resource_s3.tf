# S3 Bucket

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "s3-bucket-${var.SHORT_ENVIRONMENT_NAME}"
  acl = "public-read"
  force_destroy = true

  tags = local.common_tags
}
