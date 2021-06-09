#!/bin/bash
# 
# Shell Demo - Pre Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Pre-process script for shell demo. Gets passed in job number and creates a run directory
# for that job. 

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

# Read command line inputs
JOB_NUM=$1

echo "STARTING PRE-PROCESS JOB_NUM ${JOB_NUM}"
pwd
date

# Create Run Dir - Copy Base Inputs TODO: Check preservation of sym links?
RUN_DIR="./runs/job_${JOB_NUM}"
mkdir $RUN_DIR

echo "PRE-PROCESS JOB_NUM ${JOB_NUM} DONE"
date

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
