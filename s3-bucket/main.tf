##
# S3 bucket that can be used for lambda packages that can then be deployed
#
##
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge({
    "Name" = var.bucket_name
  }, var.tags)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
