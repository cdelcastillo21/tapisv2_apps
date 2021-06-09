#!/bin/bash
# 
# Shell Demo - Pre Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Post-process script for shell demo. Gets passed in job number and creates a run directory
# for that job. 

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

# Read command line inputs
JOB_NUM=$1

echo "STARTING POST-PROCESS FOR STORM ${JOB_NUM}"
pwd
date

RUN_DIR="./runs/job_${NUM}"

echo "POST-PROCESS FOR JOB ${JOB_NUM} DONE"

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0

