#! /bin/bash

# update packages - run it only on ec2 in public subnets as it requires internet connectivity
# yum update -y

# create script directory
scriptdir=/var/myscripts
scriptfile=consumer_script.sh
mkdir -p $scriptdir

# create data directory
datadir=/var/mydata
mkdir -p $datadir

# create log directory
logdir=/var/mylogs
logfile=log.txt
mkdir -p $logdir

# shell command to sync ec2's data directory with S3 directory (S3 => local folder on ec2)
# --delete option: deletes all files in target folder on ec2 if these files are not in S3 folder
# space needed after ! to prevent bash history substitution
# shebang may contain space before command
# ${bucket} is replaced by terraform, $datadir is ignored and replaced by bash at runtime
# terraform gives an error if there are unknown variables in curly brackets
# $datadir gets replaced by bash during execution
echo "#! /bin/bash
set -euo pipefail
aws s3 sync --delete s3://${bucket}/mydata/ $datadir/
" >> $scriptdir/$scriptfile
chmod +x $scriptdir/$scriptfile

# start http server listing all files in <datadir>
# for Python 3: sudo nohup python -m http.server 80 &
echo "Region: ${region}" >> $logdir/$logfile
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
