#!/bin/bash
# 
# SHELL DEMO  - Setup Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Basic set up required before running all job runs.
# Create run and output directories

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

echo "STARTING SETUP"
pwd
date

# Create directories for clarity 
mkdir runs                        # active job runs 
mkdir -p logs/jobs                   # log files for each job
mkdir outputs                     # output files for each job

# Make shell scripts executable 
chmod +x main.sh post_process.sh pre_process.sh

echo "SETUP DONE"
date

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
