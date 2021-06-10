#!/bin/bash
# 
# Shell Demo - Main Shell Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Main shell script called by each job
# This script will be called with ibrun by pylauncher and be executed by the adequate number of 
# independent processes, so be careful with creating/updating common job run files. 

DEBUG=true

log () {
  echo "$(date) : ${1} - ${2}" >> "logs/jobs/job_${JOB_NUM}.log"
}

if [ "$DEBUG" = true ] ; then
  set -x
  log DEBUG "Setting debug."
fi

JOB_NUM=$1

# Change to job directory
cd "runs/job_${JOB_NUM}"

log INFO "Setting Job ${JOB_NUM} parallel job."

# Do something
sleep 10
echo "Hi I AM Process Number $MPI_LOCALRANKID" >> "output.txt"

log INFO "Finished Job ${JOB_NUM} parallel job."

exit 0
