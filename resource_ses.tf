resource "aws_ses_email_identity" "email_identity" {
  email = var.SMTP_FROM != "" ? var.SMTP_FROM : var.SERVICE_DESK_EMAIL
}

resource "aws_iam_user" "smtp_user" {
  name = "smtp_user"
  tags = local.common_tags
}

resource "aws_iam_access_key" "smtp_user_access_key" {
  user = aws_iam_user.smtp_user.name
}

resource "aws_iam_user_policy" "smtp_user_policy" {
  user = aws_iam_user.smtp_user.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{"Effect":"Allow","Action":"ses:SendRawEmail","Resource":"*"}]
}
POLICY
}
