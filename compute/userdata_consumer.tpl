#!/bin/bash

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
echo "Starting SimpleHTTPServer ..." >> $logdir/$logfile
nohup python -m SimpleHTTPServer 80 &
echo "... SimpleHTTPServer is running" >> $logdir/$logfile
