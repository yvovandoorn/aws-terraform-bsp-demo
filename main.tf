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
