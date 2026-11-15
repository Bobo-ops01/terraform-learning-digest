data "aws_caller_identity" "current" {}

locals {
  function_name = "weekly-learning-digest"
  log_group_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_name}"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid       = "ReadNotes"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.notes.arn}/notes/*"]
  }

  statement {
    sid     = "InvokeOneModel"
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:aws:bedrock:*::foundation-model/${trimprefix(var.bedrock_model_id, "us.")}",
      "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_model_id}",
    ]
  }

  statement {
    sid       = "PublishDigest"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.digest.arn]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
