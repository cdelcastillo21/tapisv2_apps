#!/bin/bash
# 
# TX FEMA STORM RUNS - Generator script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Main entrypoint called by pylauncher application to generate files for pylauncher.
# Note here we just call the python script generator.py, which does the heavy lifting. 

NP=$1
STORMS=$2
PP_JOB=$3

# Generate input
python generator.py $NP $STORMS $PP_JOB

exit 0
