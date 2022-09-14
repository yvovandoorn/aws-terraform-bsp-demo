terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }

  required_version = ">= 1.0.0"

# Bucket name & Region are set by GitHub Actions
  backend "s3" {
    key    = "terraform.tfstate"
  }
}

# Expect this variables to be set by GitHub Actions
variable files-bucket-name {}
variable aws-region {}

# Set aws region from GitHub Actions
provider "aws" {
  region = "${var.aws-region}"
}

resource "aws_kms_key" "mykey" {
  description             = "Key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "files" {
  bucket = "${var.files-bucket-name}"
}

resource "aws_s3_bucket_acl" "files" {
  bucket = aws_s3_bucket.files.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "files" {
  bucket = aws_s3_bucket.files.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log-${aws_s3_bucket.files.id}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
bucket = aws_s3_bucket.files.id
rule {
  apply_server_side_encryption_by_default {
    kms_master_key_id = aws_kms_key.mykey.arn
    sse_algorithm = "aws:kms"
  }
}
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Setup the logging bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.files-bucket-name}-logbucket"
}

resource "aws_s3_bucket_acl" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
bucket = aws_s3_bucket.log_bucket.id
rule {
  apply_server_side_encryption_by_default {
    kms_master_key_id = aws_kms_key.mykey.arn
    sse_algorithm = "aws:kms"
  }
}
}

resource "aws_s3_bucket_logging" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  target_bucket = aws_s3_bucket.log_bucket2.id
  target_prefix = "log-${aws_s3_bucket.log_bucket.id}/"
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Setup the second logging bucket
resource "aws_s3_bucket" "log_bucket2" {
  bucket = "${var.files-bucket-name}-logbucket2"
}

resource "aws_s3_bucket_acl" "log_bucket2" {
  bucket = aws_s3_bucket.log_bucket2.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "log_bucket2" {
  bucket = aws_s3_bucket.log_bucket2.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket2" {
bucket = aws_s3_bucket.log_bucket2.id
rule {
  apply_server_side_encryption_by_default {
    kms_master_key_id = aws_kms_key.mykey.arn
    sse_algorithm = "aws:kms"
  }
}
}

resource "aws_s3_bucket_logging" "log_bucket2" {
  bucket = aws_s3_bucket.log_bucket2.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log-${aws_s3_bucket.log_bucket2.id}/"
}

resource "aws_s3_bucket_public_access_block" "log_bucket2" {
  bucket = aws_s3_bucket.log_bucket2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
