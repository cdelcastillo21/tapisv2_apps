#!/bin/bash
# 
# Shell Demo - Post Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Post-process script for shell demo. Gets passed in job number and creates a run directory
# for that job. 

DEBUG=true

# Read command line inputs
JOB_NUM=$1

log () {
  echo "$(date) : ${1} - ${2}" >> "logs/jobs/job_${JOB_NUM}.log"
}

if [ "$DEBUG" = true ] ; then
  set -x
  log DEBUG "Setting debug."
fi

log INFO "Post process started for job ${JOB_NUM}"

RUN_DIR="runs/job_${JOB_NUM}"

mv "${RUN_DIR}/output.txt" "outputs/job_${JOB_NUM}.txt"

# rm -rf $RUN_DIR

log INFO "Post process done for ${JOB_NUM}"

if [ "$DEBUG" = true ] ; then
  log DEBUG "Unsetting debug."
  set +x
fi

exit 0

