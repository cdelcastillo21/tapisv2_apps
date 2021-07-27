#!/usr/bin/env bash

# Pylauncher Tapis Application - Main entry-point
#   Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
#   June 2021
#
# Main entrypoint called in execution envrionment by Tapis to start the job. 

DEBUG=true

log () {
  echo "$(date) : ${1} - ${2}" >> "run.log"
}

if [ "$DEBUG" = true ] ; then
  set -x
  log DEBUG "Setting debug"
fi

# by default expect a csv file, but allow for custom (i.e. json files)
PYLAUNCHER_INPUT=${pylauncher_input:-"jobs_list.csv"}
# initialize extra args
: ${generator_args:=""}
: ${compress_outputs:=true}

# Load necessary modules - These are the modules required for all executed jobs.
module load ${custom_modules}
module list
log INFO "Staring Pylauncher Application"

# Unzip job inptus directory into job directory
unzip ${job_inputs} 

# Make sure generator script exists
if [ ! -e generator.sh ]
then
  # Exit if no generator script found
  log ERROR "Required generator script (generator.sh) not found in job input folder."
  set +x
  exit 1
fi

# Change permissions of generator script so it can be executed
chmod +x generator.sh

# If set-up script exists, run it first 
if [ -e setup.sh ]
then
  # Make set-up script executable and run
  chmod +x setup.sh
  log INFO "Running setup script"
  ./setup.sh 
fi

# Main Execution Loop:
#   - Call generator script. 
#   - Calls pylauncher on generated input file. Expected name = jobs_list.csv 
#   - Repeats until generator script returns no input file for pylauncher. 
ITER=1
while :
do
  # Call generator script - Note parent director of generator when executing is root job directory
  ./generator.sh ${ITER} $SLURM_NPROCS $generator_args
  ret=$?
  if [ $ret -ne 0 ]; then
    log ERROR "Generator script failed on iteration ${ITER}!"
    # Fail gracefully here? 
  fi

  # If input file for pylauncher has been generated, then start pylauncher
  if [ -e ${PYLAUNCHER_INPUT} ]
  then
    # Launch pylauncher on generated input file 
    log INFO "Starting pylauncher for iteration ${ITER}"
    python3 launch.py $PYLAUNCHER_INPUT
    log INFO "Pylauncher done for iteration ${ITER}"

    # Save pylauncher input file used.
    log INFO "Archiving ${ITER} pylauncher input file"
    mv ${PYLAUNCHER_INPUT} ${PYLAUNCHER_INPUT}_${ITER}
  else
    # No input for pylauncher, done. 
    log INFO "No Input for Pylauncher found on iter ${ITER}, exiting"
    break
  fi

  ITER=$(( $ITER + 1 ))
done 

log INFO "Done with execution of pylauncher applicaiton."

if [ "$compress_outputs" = true ]; then
  log INFO "Compressing logs and outputs folder"
  mv run.log logs/run.log
  cd outputs; zip -r ../outputs.zip *; cd ..
  cd logs; zip -r ../logs.zip *; cd ..
fi

if [ "$DEBUG" = true ] ; then
  log DEBUG "Unsetting debug"
  set +x
fi

exit 0
