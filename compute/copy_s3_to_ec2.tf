#---------------
# Data Providers
#---------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "copy_s3_to_ec2" {
  type        = "zip"
  source_file = "./compute/copy_s3_to_ec2.py"
  output_path = "copy_s3_to_ec2.zip"
}


#-------------------
# Locals
#-------------------
locals {
  region  = data.aws_region.current.name
  account = data.aws_caller_identity.current.account_id
}

#-------------------
# Roles and Policies
#-------------------

resource "aws_lambda_permission" "s3_invoke_lambda_permission" {
  statement_id    = "allow_s3_to_invoke_lambda"
  action          = "lambda:InvokeFunction"
  function_name   = aws_lambda_function.copy_s3_to_ec2.arn
  principal       = "s3.amazonaws.com"
  source_arn      = var.bucket_arn
  source_account  = local.account
}

resource "aws_iam_role" "copy_s3_to_ec2" {
    name               = format("%s_copy_s3_to_ec2", var.project_name)

    tags = { 
      Name = format("%s_copy_s3_to_ec2", var.project_name)
      project_name = var.project_name
    }

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

// "Resource":"arn:aws:s3:::${var.bucket}/*"
resource "aws_iam_role_policy" "copy_s3_to_ec2" {
  name    = "copy_s3_to_ec2"
  role    = aws_iam_role.copy_s3_to_ec2.id
  policy  = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "s3:GetObject"
         ],
         "Resource":"arn:aws:s3:::*"
      }
   ]
}
POLICY
}

resource "aws_iam_role_policy" "lambda_logging" {
    name   = "lambda_logging"
    role   = aws_iam_role.copy_s3_to_ec2.id
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${local.region}:${local.account}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${local.region}:${local.account}:log-group:/aws/lambda/copy_s3_to_ec2:*"
            ]
        }
    ]
}
POLICY
}


#----------------
# Lambda Function
#----------------

resource "aws_lambda_function" "copy_s3_to_ec2" {
  filename          = "copy_s3_to_ec2.zip"
  function_name     = "copy_s3_to_ec2"
  role              = aws_iam_role.copy_s3_to_ec2.arn
  handler           = "copy_s3_to_ec2.copy_s3_to_ec2"
  runtime           = "python3.7"
  description       = "A function to copy files from S3 to ec2."
  source_code_hash  = data.archive_file.copy_s3_to_ec2.output_base64sha256

  environment {
    variables = {
      "MyRegion"    = local.region 
      "MyAccountId" = local.account
    }
  }

  tags = { 
    Name = format("%s_copy_s3_to_ec2", var.project_name)
    project_name = var.project_name
  }
}


#---------------------------------
# S3 event notification for Lambda
#---------------------------------

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.copy_s3_to_ec2.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "mydata/"
    filter_suffix       = ""
  }

  depends_on = [aws_lambda_permission.s3_invoke_lambda_permission]
}
