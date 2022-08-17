terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "mondoo-demo-s3-terraform-backend"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

# Default set to AWS eu-central-1
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "website" {
  bucket_prefix = "mondoo-static-website-bucket-"
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