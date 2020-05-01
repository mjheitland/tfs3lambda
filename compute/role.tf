resource "aws_iam_role" "CopyFromS3ToEC2" {
    name               = "CopyFromS3ToEC2"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "S3ReadAccessPolicy" {
  name    = "S3ReadAccessPolicy"
  role    = aws_iam_role.CopyFromS3ToEC2.id
  policy  = <<POLICY
{ 
  "Version":"2012-10-17",
  "Statement":[ 
    { 
      "Sid": "S3ReadAccessPolicy",
      "Action":[ 
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}"
    },
    { 
      "Action":[ 
        "s3:GetObject"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "LambdaLoggingPolicy" {
    name   = "LambdaLoggingPolicy"
    role   = aws_iam_role.CopyFromS3ToEC2.id
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaLoggingPolicy",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}