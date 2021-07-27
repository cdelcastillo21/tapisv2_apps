#!/bin/bash
# 
# SHELL DEMO  - Generator 
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Main entrypoint called by pylauncher application to generate files for pylauncher.
# Note nothing is done in this case, since we have a static jobs_list.csv file defined. However
# (As of now) this file is still required by the application.

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

ITER=$1
NP=$2

echo "STARTING GENERATOR"
pwd
date

python3 generator.py $ITER $NP ${@:3}

echo "GENERATOR DONE"

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
