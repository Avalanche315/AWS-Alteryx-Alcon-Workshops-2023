# Resources

## Create a S3 Bucket
data "aws_caller_identity" "current_caller" {}

resource "aws_s3_bucket" "s3_sample_bucket" {
  bucket = "${var.bucket_base_name}-${data.aws_caller_identity.current_caller.id}"
}

## Create IAM user for accessing S3 bucket

resource "aws_iam_user" "s3_bucket_user" {
  name = "${var.s3_bucket_username}"

  tags = {
    tag-key = "alcon-workshops-s3-bucket-user"
  }
}

resource "aws_iam_access_key" "s3_bucket_user_key" {
  user = aws_iam_user.s3_bucket_user.name
}

resource "aws_iam_policy" "AlconWorkshopS3UserPolicy" {
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [ 
                "${aws_s3_bucket.s3_sample_bucket.arn}/*"
            ]
        }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "S3BucketPolicyAttachment" {
  user       = aws_iam_user.s3_bucket_user.name
  policy_arn = aws_iam_policy.AlconWorkshopS3UserPolicy.arn
}

# Outputs

output "bucket_name" {
  value = aws_s3_bucket.s3_sample_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.s3_sample_bucket.arn
}

resource "local_file" "s3_bucket_name_file" {
  content     = "User Name,Access key ID,Secret access key\n${var.s3_bucket_username},${aws_iam_access_key.s3_bucket_user_key.id},${aws_iam_access_key.s3_bucket_user_key.secret}"
  filename = "./alteryx/config/${var.s3_bucket_username}_accessKeys.csv"
}