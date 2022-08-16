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
  profile = "default"
  region  = "eu-central-1"
}

# KMS key to be used to encrypt data on buckets

resource "aws_s3_bucket" "website" {
  bucket = "mondoo-static-website-bucket"
  acl    = "public-read"
  policy  = <<EOF
{
     "id" : "MakePublic",
   "version" : "2012-10-17",
   "statement" : [
      {
         "action" : [
             "s3:GetObject"
          ],
         "effect" : "Allow",
         "resource" : "arn:aws:s3:::[BUCKET_NAME_HERE]/*",
         "principal" : "*"
      }
    ]
  }
EOF

  website {
      index_document = "index.html"
   }
}
