resource "aws_ses_email_identity" "email_identity" {
  count = var.SMTP_FROM != "" ? 1 : 0
  email = var.SMTP_FROM != "" ? var.SMTP_FROM : ""
}

resource "aws_iam_user" "smtp_user" {
  count = var.SMTP_FROM != "" ? 1 : 0
  name = "smtp_user_${var.SHORT_ENVIRONMENT_NAME}"
  tags = local.common_tags
}

resource "aws_iam_access_key" "smtp_user_access_key" {
  count = var.SMTP_FROM != "" ? 1 : 0
  user = aws_iam_user.smtp_user[0].name
}

resource "aws_iam_user_policy" "smtp_user_policy" {
  count = var.SMTP_FROM != "" ? 1 : 0
  user = aws_iam_user.smtp_user[0].name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{"Effect":"Allow","Action":"ses:SendRawEmail","Resource":"*"}]
}
POLICY
}

# Output

output "smtp_user" {
  value = var.SMTP_FROM != "" ? aws_iam_access_key.smtp_user_access_key[0].id : ""
}

output "smtp_password" {
  value = var.SMTP_FROM != "" ? aws_iam_access_key.smtp_user_access_key[0].ses_smtp_password_v4 : ""
  sensitive = true
}
