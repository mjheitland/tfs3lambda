#--- compute/main.tf

#------------
#--- Key Pair
#------------

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


#----------------
#--- Data Sources
#----------------

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
    }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }  
}  


#------------
#--- Consumer
#------------

data "template_file" "userdata_consumer" {
  template = file("${path.module}/userdata_consumer.tpl")
  vars = {
    region = var.region
    server_name = "consumer"
    bucket = var.bucket
  }
}

resource "aws_iam_role" "consumer_role" {
  name = "consumer_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "consumerAssumeEC2RolePolicy",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ec2.amazonaws.com" }
    },
    {
      "Sid": "consumerAssumeSSMRolePolicy",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ssm.amazonaws.com" }
    } 
  ]
}
EOF
  tags = {
      Name = format("%s_consumer_role", var.project_name)
      project_name = var.project_name
  }
}

resource "aws_iam_role_policy" "consumer_policy" {
  name = "consumer_policy"
  role = aws_iam_role.consumer_role.id

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"consumerS3ListBucketPolicy",
         "Effect":"Allow",
         "Action":[
            "s3:ListBucket",
            "s3:GetBucketLocation"
         ],
         "Resource":"arn:aws:s3:::${var.bucket}"
      },
      {
         "Sid":"consumerS3ReadPolicy",
         "Effect":"Allow",
         "Action":[
            "s3:GetObject",
            "s3:GetObjectAcl"
         ],
         "Resource":"arn:aws:s3:::${var.bucket}/*"
      },

      {
         "Sid":"consumerCloudwatchPolicy",
         "Effect":"Allow",
         "Action":[
            "cloudwatch:*",
            "logs:*"
         ],
         "Resource":"*"
      },

      {
         "Sid":"consumerSSMPolicy",
         "Effect":"Allow",
         "Action":[
            "ec2:DescribeInstanceStatus",            
            "ec2messages:*",
            "ssmmessages:*",
            "ssm:CancelCommand",
            "ssm:DescribeDocument",
            "ssm:DescribeDocumentParameters",
            "ssm:DescribeInstanceInformation",
            "ssm:DescribeInstanceProperties",
            "ssm:GetDocument",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations",
            "ssm:ListDocuments",
            "ssm:ListDocumentVersions"
         ],
         "Resource":"*"
      },

      {
         "Sid":"consumerSSMSendCommandPolicy",
         "Effect":"Allow",
         "Action":"ssm:*",
         "Resource":[
            "arn:aws:ec2:${var.region}:${var.account_id}:instance/*",
            "arn:aws:ssm:${var.region}:*:document/*"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_instance_profile" "consumer_profile" {
  name = "consumer_profile"
  role = aws_iam_role.consumer_role.name
}

resource "aws_instance" "consumer" {
  instance_type           = "t3.micro"
  ami                     = data.aws_ami.amazon_linux_2.id
  key_name                = aws_key_pair.keypair.id
  subnet_id               = var.subpub1_id
  vpc_security_group_ids  = [var.sgpub1_id]
  user_data               = data.template_file.userdata_consumer.*.rendered[0]
  iam_instance_profile    = aws_iam_instance_profile.consumer_profile.name
  tags = { 
    Name = format("%s_consumer", var.project_name)
    project_name = var.project_name
  }
}


#------------
#--- Provider
#------------

data "template_file" "userdata_provider" {
  template = file("${path.module}/userdata_provider.tpl")
  vars = {
    region = var.region
    server_name = "provider"
    bucket = var.bucket
    consumer_id = (aws_instance.consumer.*.id)[0]
  }

  # Do not remove this line, depends_on is needed to attach role_policy to role!
  depends_on = [aws_lambda_permission.s3_invoke_lambda_permission, aws_instance.consumer]
}

resource "aws_iam_role" "provider_role" {
  name = "provider_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "providerAssumeEC2RolePolicy",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ec2.amazonaws.com" }
    },
    {
      "Sid": "providerAssumeSSMRolePolicy",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ssm.amazonaws.com" }
    }
  ]
}
EOF
  tags = {
      Name = format("%s_provider_role", var.project_name)
      project_name = var.project_name
  }
}

resource "aws_iam_role_policy" "provider_policy" {
  name = "provider_policy"
  role = aws_iam_role.provider_role.id

  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"providerS3ListBucketPolicy",
         "Action":[
            "s3:GetBucketLocation",
            "s3:ListBucket"
         ],
         "Effect":"Allow",
         "Resource":"arn:aws:s3:::${var.bucket}"
      },
      {
         "Sid":"providerS3ReadAndWritePolicy",
         "Effect":"Allow",
         "Action":[
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:PutObjectAcl"
         ],
         "Resource":"arn:aws:s3:::${var.bucket}/*"
      },
      
      {
         "Sid":"providerCloudwatchPolicy",
         "Effect":"Allow",
         "Action":[
            "cloudwatch:*",
            "logs:*"
         ],
         "Resource":"*"
      },

      {
         "Sid":"providerSSMPolicy",
         "Effect":"Allow",
         "Action":[
            "ec2:DescribeInstanceStatus",            
            "ec2messages:*",
            "ssmmessages:*",
            "ssm:CancelCommand",
            "ssm:DescribeDocument",
            "ssm:DescribeDocumentParameters",
            "ssm:DescribeInstanceInformation",
            "ssm:DescribeInstanceProperties",
            "ssm:GetDocument",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations",
            "ssm:ListDocuments",
            "ssm:ListDocumentVersions"
         ],
         "Resource":"*"
      },

      {
         "Sid":"providerSSMSendCommandPolicy",
         "Effect":"Allow",
         "Action":"ssm:*",
         "Resource":[
            "arn:aws:ec2:${var.region}:${var.account_id}:instance/*",
            "arn:aws:ssm:${var.region}:*:document/*"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_instance_profile" "provider_profile" {
  name = "provider_profile"
  role = aws_iam_role.provider_role.name
}

resource "aws_instance" "provider" {
  instance_type           = "t3.micro"
  ami                     = data.aws_ami.amazon_linux_2.id
  key_name                = aws_key_pair.keypair.id
  subnet_id               = var.subpub1_id
  vpc_security_group_ids  = [var.sgpub1_id]
  user_data               = data.template_file.userdata_provider.*.rendered[0]
  iam_instance_profile    = aws_iam_instance_profile.provider_profile.name
  tags = { 
    Name = format("%s_provider", var.project_name)
    project_name = var.project_name
  }

  # Do not remove this line, Provider needs instance id of consumer!
  depends_on = [aws_instance.consumer]
}
