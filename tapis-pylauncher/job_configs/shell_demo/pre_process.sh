#!/bin/bash
# 
# Shell Demo - Pre Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Pre-process script for shell demo. Gets passed in job number and creates a run directory
# for that job. 

DEBUG=true

# Read command line inputs
JOB_NUM=$1

log () {
  echo "$(date) : ${1} - ${2}" >> "logs/jobs/job_${JOB_NUM}.log"
}

if [ "$DEBUG" = true ] ; then
  log DEBUG "Setting debug."
  set -x
fi

log INFO "Starting pre-processing for job ${JOB_NUM}"

# Create direcotry for job in runs directory
RUN_DIR="runs/job_${JOB_NUM}"
mkdir $RUN_DIR

log INFO "Pre-processing for job ${JOB_NUM} done."

if [ "$DEBUG" = true ] ; then
  log DEBUG "Unsetting debug."
  set +x
fi

exit 0
