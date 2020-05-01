# Copying files between two EC2 instances using S3 and Lambda (triggered by S3 events) with SSM

The following components get created:
+ 1 S3 bucket
+ 1 key pair (run ssh-keygen in your home folder to create a key "~/.ssh/tfvpce/id_rsa.pub")
+ 1 VPC with one public subnet, internet gateway, route table and a security group
+ 2 ec2
+ 1 Lambda to copy files from S3 to consumer (gets triggered by S3 events whenever the provider puts files into S3)

## Generate a keypair to access EC2 instances

    ssh-keygen

## Terraform commands
    
    terraform init
    
    terraform validate
    
    terraform plan -out=tfplan
    
    terraform apply -auto-approve tfplan
    or
    terraform apply -auto-approve
    
    terraform destroy -auto-approve

## To delete Terraform state files
    rm -rfv **/.terraform # remove all recursive subdirectories
    
<br>

## Link: 
<a href="https://cloudbriefly.com/post/running-ssm-agent-in-an-aws-lambda-function/">Running SSM Agent in an AWS Lambda Function</a>
