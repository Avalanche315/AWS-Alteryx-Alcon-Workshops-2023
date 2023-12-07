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

# Variables

variable sender_email_address {}

variable recipient_email_address {}

# Modules

## Create the S3 bucket

module "amazon_s3_data" {
  source             = "./modules/terraform-aws-s3"
  bucket_base_name   = "alcon-workshop-notification"
  s3_bucket_username = "alcon-workshops-s3-user-account"
}

## Creating lambda for notification system

module "aws_lambda_notification" {
  source            = "./modules/terraform-aws-lambda"
  s3_bucket_arn     = module.amazon_s3_data.bucket_arn
  s3_bucket_name    = module.amazon_s3_data.bucket_name
  handler           = "src.lambda_s3_trigger.lambda_handler"
  runtime           = "python3.9"
  zip_location      = "${path.module}/dist/lambda_code.zip"
  timeout           = 180 # In seconds
  sender_email_address    = var.sender_email_address
  recipient_email_address = var.recipient_email_address
}

# Outputs (Optional)

output "aws_s3_data_bucket_arn" {
  value = module.amazon_s3_data.bucket_arn
}

output "aws_s3_data_bucket_name" {
  value = module.amazon_s3_data.bucket_name
}

output "aws_lambda_data_lambda_name" {
  value = module.aws_lambda_notification.lambda_name
}

output "aws_lambda_data_lambda_arn" {
  value = module.aws_lambda_notification.lambda_arn
}

# Save S3 bucket name in a .txt file

resource "local_file" "s3_bucket_name_file" {
  content     = "s3_bucket_name\n${module.amazon_s3_data.bucket_name}"
  filename = "./alteryx/config/s3_bucket_name.txt"
}