data "aws_iam_policy_document" "scheduler_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.function_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json
}

data "aws_iam_policy_document" "scheduler_permissions" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.digest.arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = "${local.function_name}-scheduler-policy"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_permissions.json
}

resource "aws_scheduler_schedule" "weekly" {
  name                         = "${local.function_name}-weekly"
  schedule_expression          = "cron(0 18 ? * SUN *)"
  schedule_expression_timezone = "Africa/Nairobi"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.digest.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}
