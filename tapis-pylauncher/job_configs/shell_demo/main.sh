#!/bin/bash
# 
# Shell Demo - Main Shell Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Main shell script called by each job

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

JOB_NUM=$1

# Change to job directory
cd "runs/job_${JOB_NUM}"

echo "Starting Job ${JOB_NUM}\n" > output.txt
pwd

# Do something
sleep 10

echo "Finished Job ${JOB_NUM}\n" >> output.txt
pwd

exit 0
