resource "aws_sns_topic" "digest" {
  name = "weekly-digest"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.digest.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
