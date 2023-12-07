# Create Lambda IAM role

## Create an execution role that grants a Lambda function permission to access AWS
## services and resources.
resource "aws_iam_role" "lambda_s3_trigger_role" {
  name = "alcon-workshops-lambda-s3-trigger-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}


## Add policy to give Lambda Function permission to get objects from an Amazon S3 bucket
## and to write to Amazon CloudWatch Logs.
resource "aws_iam_policy" "s3_lambda_policy" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect": "Allow",
        "Action": [
          "logs:*"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        
      },
      {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
        ],
        "Resource" : [
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_lambda_policy_attachment" {
  role       = aws_iam_role.lambda_s3_trigger_role.name
  policy_arn = aws_iam_policy.s3_lambda_policy.arn
}

## Add policy to give Lambda Function permission to send emails with SES
resource "aws_iam_policy" "ses_lambda_policy" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect": "Allow",
        "Action": [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ses_lambda_policy_attachment" {
  role       = aws_iam_role.lambda_s3_trigger_role.name
  policy_arn = aws_iam_policy.ses_lambda_policy.arn
}

# Create Lambda function

resource "aws_lambda_function" "s3_trigger_lambda" {
  function_name    = "alcon-workshops-lambda"
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_s3_trigger_role.arn
  source_code_hash = filebase64sha256(var.zip_location) 
  filename         = var.zip_location
  timeout          = var.timeout
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:11"]

  environment {
    variables = {
      # both emails have to be verified for Amazon SES Sandbox; set values in terraform.tfvars
      SENDER_EMAIL_ADDRESS = var.sender_email_address
      RECIPIENT_EMAIL_ADDRESS = var.recipient_email_address
    }
  }
}

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "s3_trigger_notification" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Create Email identities for sender and recipient

resource "aws_ses_email_identity" "ses_sender_email_identity" {
  email = var.sender_email_address  # needs to be verified
}

resource "aws_ses_email_identity" "ses_recipient_email_identity" {
  email = var.recipient_email_address  # recipient also needs to be verified in SES Sandbox
}

# Outputs

output "lambda_arn" {
  value = aws_lambda_function.s3_trigger_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.s3_trigger_lambda.function_name
}