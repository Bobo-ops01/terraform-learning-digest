variable "aws_region" {
  type        = string
  description = "Region where Bedrock model access is enabled"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use"
  default     = "default"
}

variable "bedrock_model_id" {
  type        = string
  description = "Bedrock model ID the Lambda is allowed to invoke"
}

variable "notification_email" {
  type        = string
  description = "Email address that receives the digest"
}
