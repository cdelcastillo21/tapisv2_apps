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

mkdir -p runs                        # active job runs 
mkdir -p outputs                     # output files for each storm

# Make shell scripts executable in job config dir 
chmod +x main.sh

echo "SETUP DONE"
date

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
