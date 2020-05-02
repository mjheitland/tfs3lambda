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
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" }
    },
    {
      "Sid": "consumerAssumeSSMRolePolicy",
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {"Service": "ssm.amazonaws.com"}
    } 
  ]
}
EOF
  tags = {
      Name = format("%s_consumer_role", var.project_name)
      project_name = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "consumer_ssm_attachment" {
  role       = aws_iam_role.consumer_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_activation" "consumer_ssm_activation" {
  name               = "consumer_ssm_activation"
  description        = "Activate SSM"
  iam_role           = aws_iam_role.consumer_role.id
  registration_limit = "5"
  depends_on         = [aws_iam_role_policy_attachment.consumer_ssm_attachment]
}

resource "aws_iam_role_policy" "consumer_policy" {
  name = "consumer_policy"
  role = aws_iam_role.consumer_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[ 
    { 
      "Sid": "consumerS3FullAccessPolicy",
      "Action":[ 
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}"
    },
    { 
      "Action":[ 
        "s3:GetObject",
        "s3:GetObjectAcl"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}/*"
    },
    {
            "Sid": "SSMRead",
            "Effect": "Allow",
            "Action": [
                "ssm:*",
                "ssm:GetAutomationExecution",
                "ssm:GetParameters",
                "ssm:ListCommands",
                "ssm:StartAutomationExecution"
            ],
            "Resource": [
                "*"
            ]
        }
  ]}
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
  depends_on = [aws_lambda_permission.s3_invoke_lambda_permission, aws_instance.consumer]
}

resource "aws_iam_role" "provider_role" {
  name = "provider_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProviderAssumeEC2RolePolicy",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    },
    {
      "Sid": "providerAssumeSSMRolePolicy",
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {"Service": "ssm.amazonaws.com"}
    }
  ]
}
EOF
  tags = {
      Name = format("%s_provider_role", var.project_name)
      project_name = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "provider_ssm_attachment" {
  role       = aws_iam_role.provider_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_activation" "provider_ssm_activation" {
  name               = "provider_ssm_attachment"
  description        = "Activate SSM"
  iam_role           = aws_iam_role.provider_role.id
  registration_limit = "5"
  depends_on         = [aws_iam_role_policy_attachment.provider_ssm_attachment]
}

resource "aws_iam_role_policy" "provider_policy" {
  name = "provider_policy"
  role = aws_iam_role.provider_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[ 
    { 
      "Sid": "ProviderS3FullAccessPolicy",
      "Action":[ 
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}"
    },
    { 
      "Action":[ 
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ],
      "Effect":"Allow",
      "Resource":"arn:aws:s3:::${var.bucket}/*"
    },
    {
        "Sid": "SSMWrite",
        "Effect": "Allow",
        "Action": [ 
            "ssm:*",
            "ssm:SendCommand"
        ],
        "Resource": [
            "arn:aws:s3:::${var.bucket}",
            "arn:aws:ec2:${var.region}:${var.account_id}:instance/${aws_instance.consumer.*.id[0]}",
            "arn:aws:ssm:${var.region}:${var.account_id}:document/AWS-ApplyPatchBaseline",
            "arn:aws:ssm:${var.region}:${var.account_id}:document/AWS-RunShellScript",            
            "arn:aws:ssm:${var.region}:${var.account_id}:document/RestartServices"            
        ]
    }
  ]}
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

  depends_on = [aws_instance.consumer]
}

