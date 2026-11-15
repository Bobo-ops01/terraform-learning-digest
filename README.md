# terraform-learning-digest

A weekly learning digest on AWS, built with Terraform. Once a week, a Lambda function reads my study notes from S3, asks Amazon Bedrock to turn them into a short digest, and emails it to me through SNS.

## How it works

```
EventBridge Scheduler (weekly) -> Lambda -> S3 (notes) -> Bedrock -> SNS -> email
```

1. EventBridge Scheduler invokes the Lambda every Sunday at 6 PM (Africa/Nairobi).
2. Lambda reads `notes/learning.txt` from the S3 bucket.
3. Lambda sends the notes to a Bedrock model through the Converse API, asking for a summary, key takeaways, and two things to review next week.
4. Lambda publishes the digest to an SNS topic, which emails it to a confirmed subscriber.

## Security choices

- **Least privilege.** The Lambda role can only read objects under `notes/`, invoke one Bedrock model, publish to one SNS topic, and write to its own log group.
- **Scoped scheduler role.** The scheduler's role can only invoke this one function.
- **Bucket hardening.** Public access is blocked and server-side encryption is on.
- **No notes in logs.** The function logs only the character count.
- **Capped input.** Notes are truncated to 20,000 characters to keep costs predictable.
- **Personal data stays local.** `terraform.tfvars` (which holds the email address) and the `notes/` folder are git-ignored.

## Least privilege proof

Tested with the IAM policy simulator against the notes file:

| Action | Result |
|--------|--------|
| `s3:GetObject` | allowed |
| `s3:PutObject` | implicitDeny |
| `s3:DeleteObject` | implicitDeny |

The function can read the notes but cannot change or delete them.

## Project layout

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider versions |
| `variables.tf` | Region, AWS profile, model ID, notification email |
| `s3.tf` | Notes bucket with encryption and public access blocked |
| `sns.tf` | SNS topic and email subscription |
| `iam.tf` | Lambda role and least-privilege policy |
| `lambda.tf` | Lambda function and log group |
| `scheduler.tf` | Weekly schedule and its role |
| `lambda/handler.py` | Python code that calls Bedrock and publishes the digest |

## Prerequisites

- Terraform 1.5 or newer
- AWS CLI with a profile that can create S3, IAM, SNS, Lambda, and Scheduler resources
- Bedrock access enabled for your chosen model in your chosen Region

## Deploy

Create a `terraform.tfvars` file (it is git-ignored):

```hcl
aws_region         = "your-region"
aws_profile        = "default"
bedrock_model_id   = "your-model-id"
notification_email = "you@example.com"
```

Then run:

```bash
terraform init
terraform plan
terraform apply
```

AWS sends a confirmation email to the address above. Click **Confirm subscription**, or no digests will be delivered.

## Add notes and test

```bash
BUCKET=$(aws s3 ls | grep learning-digest | awk '{print $3}')
aws s3 cp notes/learning.txt s3://$BUCKET/notes/learning.txt
aws lambda invoke --function-name weekly-learning-digest /tmp/out.json
```

Check your inbox (and spam) for the digest. If it does not arrive, read the logs:

```bash
aws logs tail /aws/lambda/weekly-learning-digest --since 10m
```

## Clean up

```bash
aws s3 rm s3://$BUCKET --recursive
terraform destroy
```

## Limitations and next steps

- Reads a single text file, uploaded manually. Reading a whole folder of notes would be a next step.
- Plain-text email only.
- No retries or dead-letter queue if a run fails.
- A separate project for automated job alerts is planned.
