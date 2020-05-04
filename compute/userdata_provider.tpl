#! /bin/bash

# update packages - run it only on ec2 in public subnets as it requires internet connectivity
# yum update -y

# provider script is a shell script that runs on the provider: 
# generates file every minute and uploads it to s3
# and starts consumer script on consumer using ssm to download file from s3
providerscript=provider_script.sh
consumerscript=consumer_script.sh

# create script directory
scriptdir=/var/myscripts
mkdir -p $scriptdir

# create data directory
datadir=/var/mydata
mkdir -p $datadir

# create log directory
logdir=/var/mylogs
logfile=log.txt
mkdir -p $logdir

# provider script runs on provider: generates a file every minute and loads it up to S3, starts a consumer script to download it from s3
# We are running the following aws ssm command:
#   aws ssm send-command --region=eu-west-1 --instance-ids "i-12345678" --document-name "AWS-RunShellScript" --comment "run shell script on ec2" --parameters '{"commands":["#!/usr/bin/bash","source /var/myscripts/consumer_script.sh"]}'
# within '...' nothing will be replaced by bash
# set -: enable option; set +: disable option
# set -euo: e = exit if any command fails, u = exit on undefined variable access, set -o pipefail = exit if command within pipe fails
# set +H: disables history substitution, i.e. ! in double-quoted strings
# example output for date +"%Y-%m-%d_%T.txt": 2020-05-03_21:35:35.txt
# Terraform will substitute $ + curly brackets with variable, e.g. ${region}
# $(...): bash will execute "..." and replace with command output
# '"'"' is ' in a single-quoted string in bash
echo '#!/bin/bash
set -euo pipefail
set +H
filename="/var/mydata/$(date +"%Y-%m-%d_%T.txt")"
echo "$(whoami): Hello World!" > "$filename"
chown ec2-user "$filename"
aws s3 cp --recursive /var/mydata/ s3://${bucket}/mydata/
aws ssm send-command --region=${region} --instance-ids "${consumer_id}" --document-name "AWS-RunShellScript" --comment "run shell script on ec2" --parameters '"'"'{"commands":["#!/usr/bin/bash","source /var/myscripts/consumer_script.sh"]}'"'"'
rm -rf /var/mydata/*
' > $scriptdir/$providerscript
chmod +x $scriptdir/$providerscript

# add cron task to run provider script every minute, runs under ec2-user
cronpath=/var/spool/cron/ec2-user
echo "*/1 * * * * /var/myscripts/provider_script.sh" >> $cronpath

# start http server listing all files in <datadir>
# for Python 3: sudo nohup python -m http.server 80 &
echo "Region: ${region}" >> $logdir/$logfile
echo "Consumer id:  ${consumer_id}" >> $logdir/$logfile
echo "Server name: ${server_name}" >> $logdir/$logfile
echo "whoami: $(whoami)" >> $logdir/$logfile
aws --version >> $logdir/$logfile
yum info amazon-ssm-agent >> $logdir/$logfile
echo "Starting SimpleHTTPServer ..." >> $logdir/$logfile
cd $datadir
nohup python -m SimpleHTTPServer 80 &
echo "... SimpleHTTPServer is running" >> $logdir/$logfile

# change ownership to ec2-user
chown -R ec2-user $scriptdir
chown -R ec2-user $datadir
chown -R ec2-user $logdir

# set alias for testing
# We see this crazy single/double quote nightmare
# because we have to encode single quotes within
# single quotes within single quotes
echo 'alias sm='"'"'aws ssm send-command --region eu-west-1 --instance-ids "${consumer_id}" --document-name "AWS-RunShellScript" --comment "run shell script on ec2" --parameters '"'"'"'"'"'"'"'"'{"commands":["#!/usr/bin/bash","source /var/myscripts/consumer_script.sh"]}'"'"'"'"'"'"'"'"''"'"'' >> /home/ec2-user/.bashrc
chown ec2-user /home/ec2-user/.bashrc
