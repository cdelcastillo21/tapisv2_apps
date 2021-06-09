#!/usr/bin/env bash

# Pylauncher Tapis Application - Main entry-point
#   Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
#   June 2021
#
# Main entrypoint called in execution envrionment by Tapis to start the job. 

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

PYLAUNCHER_INPUT="jobs_list.csv"

# Load necessary modules - These are the modules required for all executed jobs.
module load ${custom_modules}
module list
pwd
echo "STARTING"
date

# Copy job_configs to run directory. 
# Use rsync since there may be a decent bit of data packaged if singularity images included
# Note if job_configs is listed as an input and not a parameter then we don't need to do this step.
# rsync -a --info=progress2 ${job_configs} job_configs 

ls -lat 

# Make sure generator script exists
if [ ! -e ./job_configs/generator.sh ]
then
  # Exit if no generator script found
  echo "ERROR - Required generator script (generator.sh) not found in job_configs folder."
  set +x
  exit 1
fi

# Change permissions of generator script so it can be executed
chmod +x ./job_configs/generator.sh

# If set-up script exists, run it first 
if [ -e ./job_configs/setup.sh ]
then
  # Make set-up script executable and run
  chmod +x ./job_configs/setup.sh
  echo "Running setup script"
  ./job_configs/setup.sh 
fi

# Main Execution Loop:
#   - Call generator script. Biggest concern here is set-up for generator script run environment. 
#   - Calls pylauncher on generated input file. Expected name = jobs_list.csv 
#   - REPEAT until generator script returns no input file for pylauncher. 
ITER=1
while :
do
  # Call generator script - Note parent director of generator when executing is root job directory
  ./job_configs/generator.sh ${ITER} ${NP} ${generator_args}

  # If input file for pylauncher has been generated, then start pylauncher
  if [ -e ./${PYLAUNCHER_INPUT} ]
  then
    # Launch pylauncher on generated input file 
    echo "Starting Pylauncher"
    python launch.py

    # Save pylauncher input file used.
    echo "Archiving pylauncher input ilfe"
    mv ${PYLAUNCHER_INPUT} ${PYLAUNCHER_INPUT}_${ITER}
  else
    # No input for pylauncher, done. 
    echo "No Input for Pylauncher found, exiting"
    break
  fi

  ITER=$(( $ITER + 1 ))
done 

date
echo "DONE"

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
