terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
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

resource "aws_s3_bucket" "website" {
  bucket = "${var.website-bucket-name}"

# Per https://registry.terraform.io/providers/hashicorp/aws/3.75.2/docs/resources/s3_bucket_website_configuration
# Per https://registry.terraform.io/providers/hashicorp/aws/3.75.2/docs/resources/s3_bucket_acl
  lifecycle {
  ignore_changes = [
    grant,
    website
  ]
}
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