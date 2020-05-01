#! /bin/bash

# update packages - run it only on ec2 in public subnets as it requires internet connectivity
# yum update -y

# create data directory
datadir=/var/mydata
mkdir -p $datadir
chown -R ec2-user $datadir

# create log directory
logdir=/var/mylogs
logfile=log.txt
mkdir -p $logdir
chown -R ec2-user $logdir

# start http server listing all files in <datadir>
# for Python 3: sudo nohup python -m http.server 80 &
echo "Server name: ${server_name}" >> $logdir/$logfile
aws --version >> $logdir/$logfile
yum info amazon-ssm-agent >> $logdir/$logfile
echo "Starting SimpleHTTPServer ..." >> $logdir/$logfile
nohup python -m SimpleHTTPServer 80 &
echo "... SimpleHTTPServer is running" >> $logdir/$logfile
