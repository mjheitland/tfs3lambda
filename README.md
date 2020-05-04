# Copying files between two EC2 instances using S3 and Lambda (triggered by S3 events) with SSM

Provider ec2 instance creates a file every minute (cron task), uploads it to S3 and 
uses SSM to run a consumer script on the consumer ec2 to sync consumer's data directory with S3 bucket.

The following components get created:
+ 1 S3 bucket
+ 1 key pair (run ssh-keygen in your home folder to create a key "~/.ssh/tfvpce/id_rsa.pub")
+ 1 VPC with one public subnet, internet gateway, route table and a security group
+ 2 ec2
+ 1 Lambda to log files added to S3 (gets triggered by S3 events whenever the provider puts files into S3)

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

## Links: 

<a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html">Setting up AWS Systems Manager</a>

<a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/walkthrough-cli.html#walkthrough-cli-examples">SSM Run Command</a>

<a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/security_iam_id-based-policy-examples.html">AWS Systems Manager identity-based policy examples</a>

Example 1 - ipconfig:
aws ssm send-command --region eu-west-1 --instance-ids "$ec2_instance_id" --document-name "AWS-RunShellScript" --comment "IP config" --parameters commands=ifconfig --output text

Example 2 - get instance details:
aws ssm describe-instance-information --region eu-west-1 --instance-information-filter-list key=InstanceIds,valueSet=<ec2 instance id> --region eu-west-1

Example 3 - run a Python script on the instance:
sh_command_id=$(aws ssm send-command --instance-ids "$ec2_instance_id" --document-name "AWS-RunShellScript" --comment "Demo run shell script on Linux Instances" --parameters '{"commands":["#!/usr/bin/python","print \"Hello world from python\""]}' --output text --query "Command.CommandId" --region eu-west-1) sh -c 'aws ssm list-command-invocations --command-id "$sh_command_id" --details --query "CommandInvocations[].CommandPlugins[].{Status:Status,Output:Output}"'

Example 4 - run a Bash script on the instance:
aws ssm send-command --region eu-west-1 --instance-ids "$ec2_instance_id" --document-name "AWS-RunShellScript" --comment "run shell script on ec2" --parameters '{"commands":["#!/usr/bin/bash","source /var/myscripts/consumer-script.sh"]}'
