#! /bin/bash

# update packages - run it only on ec2 in public subnets as it requires internet connectivity
# yum update -y

# create script directory
scriptdir=/var/myscripts
scriptfile=generate-file.sh
mkdir -p $scriptdir

# create data directory
datadir=/var/mydata
mkdir -p $datadir
chown -R ec2-user $datadir

# create log directory
logdir=/var/mylogs
logfile=log.txt
mkdir -p $logdir
chown -R ec2-user $logdir

# shell command to generate a new file and upload it to S3 folder
# space needed after ! to prevent bash history substitution
# shebang may contain space before command
# ${bucket} is replaced by terraform, $datadir is ignored and replaced by bash at runtime
# terraform gives an error if there are unknown variables in curly brackets
echo "
#! /bin/bash
set -euo pipefail
echo \"Hello World! \" > \"$datadir/\$(date +\"%Y-%m-%d_%T.txt\")\"
aws s3 cp --recursive $datadir/ s3://${bucket}/mydata/
rm -rf $datadir/*
" >> $scriptdir/$scriptfile
chmod +x $scriptdir/$scriptfile

# add cron task to generate a new file, runs every minute under 'ec2-user' account
cronpath=/var/spool/cron/ec2-user
echo "*/1 * * * * /var/myscripts/generate-file.sh" >> $cronpath

# start http server listing all files in <datadir>
# for Python 3: sudo nohup python -m http.server 80 &
echo "Server name: ${server_name}" >> $logdir/$logfile
aws --version >> $logdir/$logfile
yum info amazon-ssm-agent >> $logdir/$logfile
echo "Starting SimpleHTTPServer ..." >> $logdir/$logfile
nohup python -m SimpleHTTPServer 80 &
echo "... SimpleHTTPServer is running" >> $logdir/$logfile
