#!/bin/bash
# 
# TX FEMA STORM RUNS - Pre Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Pre-process script for running TX FEMA storms
#   Creates run director for storm run
#   Stages input -> Links input files (base + wind,press data) to run directory
#   Navigates to run director and runs adcprep 

DEBUG=true

# Read command line inputs
STORM_NUM=$1
ADCIRC_RUN_PROC=$2
LOG_FILE=$(pwd)"/logs/runs/s${STORM_NUM}_pre.log"

log () {
  echo "$(date) : ${1} - ${2}" >> $LOG_FILE
}

if [ "$DEBUG" = true ] ; then
  log DEBUG "Setting debug."
  set -x
fi

log INFO "Starting pre-process for storm ${STORM_NUM}"

# Create Run Dir - Copy Base Inputs TODO: Check preservation of sym links?
RUN_DIR="runs/s${STORM_NUM}"
cp -r --preserve=links ./mesh $RUN_DIR

# Copy wind and pressure files for strom to run directory 
cp --preserve=links storms/TEX_FEMA_RUN$STORM_NUM.pre $RUN_DIR/fort.221
cp --preserve=links storms/TEX_FEMA_RUN$STORM_NUM.WND $RUN_DIR/fort.222

cd $RUN_DIR

# Copy adcprep executables to run directory (if needed)
[ -f adcprep ] || ln -s ../../adcprep .

# Run ADCPREP
log INFO "Starting ADCPREP first execution."
printf '%s\n1\nfort.14\n' "$ADCIRC_RUN_PROC" | ./adcprep >> $LOG_FILE
log INFO "ADCPREP first execution done."

log INFO "Starting ADCPREP second execution."
printf '%s\n2\n' "$ADCIRC_RUN_PROC" | ./adcprep >> $LOG_FILE
log INFO "ADCPREP second execution done."

log INFO "Finished pre-process for storm ${STORM_NUM}"

if [ "$DEBUG" = true ] ; then
  log DEBUG "Unsetting debug."
  set +x
fi

exit 0
