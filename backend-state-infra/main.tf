##
# S3 bucket that can be used for ELB access-logs storage
#
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
##

locals {
  bucket_policy = templatefile("${path.module}/policies/bucket-policy-template.json", local.template_vars)
  template_vars = {
    bucket_name = var.bucket_name
  }
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = merge({
    "Name" = var.bucket_name
  }, var.tags)
}

resource "aws_s3_bucket_versioning" "versioning_main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership_main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "allow_ssl_requests_only" {
  bucket = aws_s3_bucket.main.id
  policy = local.bucket_policy
}

# So the bucket is private by default, but objects
# within the bucket can be made public.  The resource
# below prevents that, providing greater security
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge({
    "Name" = var.dynamodb_table_name
  }, var.tags)
}
