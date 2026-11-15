resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "notes" {
  bucket = "learning-digest-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "notes" {
  bucket = aws_s3_bucket.notes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "notes" {
  bucket = aws_s3_bucket.notes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
