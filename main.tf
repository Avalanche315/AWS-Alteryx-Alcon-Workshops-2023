# Terraform and AWS configurations

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

module "amazon_s3_data" {
  source             = "./modules/terraform-aws-s3"
  bucket_base_name   = "alcon-workshop-notification"
  s3_bucket_username = "alcon-workshops-s3-user-account"

# Outputs (Optional)

output "aws_s3_data_bucket_arn" {
  value = module.amazon_s3_data.bucket_arn
}

output "aws_s3_data_bucket_name" {
  value = module.amazon_s3_data.bucket_name
}

# Save S3 bucket name in a .txt file

resource "local_file" "s3_bucket_name_file" {
  content     = "s3_bucket_name\n${module.amazon_s3_data.bucket_name}"
  filename = "./alteryx/config/s3_bucket_name.txt"
}