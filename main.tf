terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }

  required_version = ">= 0.14.9"

# Bucket name & Region are set by GitHub Actions
  backend "s3" {
    key    = "terraform.tfstate"
  }
}

# Expect this variables to be set by GitHub Actions
variable website-bucket-name {}
variable aws-region {}

# Set aws region from GitHub Actions
provider "aws" {
  region = "${var.aws-region}"
}

resource "aws_kms_key" "mykey" {
  description             = "Key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "website" {
  bucket = "${var.website-bucket-name}"
}

resource "aws_s3_bucket_acl" "website" {
  bucket = aws_s3_bucket.website.id
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow",
        Action = "s3:GetObject"
        Resource = [
          aws_s3_bucket.website.arn, 
          "${aws_s3_bucket.website.arn}/*",
        ]
        Principal = "*"
      },
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

####
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "website" {
  bucket = aws_s3_bucket.website.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log-${aws_s3_bucket.website.id}/"
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  block_public_policy = true
  block_public_acls = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
bucket = aws_s3_bucket.website.id
rule {
  apply_server_side_encryption_by_default {
    kms_master_key_id = aws_kms_key.mykey.arn
    sse_algorithm = "aws:kms"
  }
}
}