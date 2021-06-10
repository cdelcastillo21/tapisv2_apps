##!/bin/bash
# 
# TX FEMA STORM RUNS - Post Process Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Post-process script to be run after an individual storm run.
#   Create storm specific output directory 
#   Cleans up netcdf files that have redundant attributes (these break python's xarray library when
#     trying to load the file. No information lost).
#   Moves desired output files to output directory
#   Move log files to output directory for storm
#   Delete run directory (DISABLE for now -> default enable later, add debug option to not to)

DEBUG=true

# Read command line inputs
STORM_NUM=$1

log () {
  echo "$(date) : ${1} - ${2}" >> "logs/runs/s${STORM_NUM}_post.log"
}

if [ "$DEBUG" = true ] ; then
  set -x
  log DEBUG "Setting debug."
fi

log INFO "Starting post-process for storm ${STORM_NUM}"

RUN_DIR="runs/s${STORM_NUM}"

# Make output DIR
OUT_DIR="output/runs/s${NUM}"
mkdir $OUT_DIR

# Create start timestamp file
START_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "${RUN_DIR}/ts_post_start_${START_TS}"

log INFO "Cleaning output .nc files."

# Clean netcdf adcirc files - Put clean versions in output dir
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/fort.61.nc" "${OUT_DIR}/fort.61.nc"
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/fort.63.nc" "${OUT_DIR}/fort.63.nc"
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/maxele.63.nc" "${OUT_DIR}/maxele.63.nc"

# Make logs directory for this specific storm run
mkdir logs/runs/s${STORM_NUM}

# Move log files in run directory to log folder for storm
mv "${RUN_DIR}/*.log" "logs/runs/s${STORM_NUM}/"

# Remove Parallel run directory 
# rmdir -rf $RUN_DIR

log INFO "Finishing post-process for storm ${STORM_NUM}"

# Move logs into storm specific folder 
mv "logs/runs/s${STORM_NUM}_*.log" "logs/runs/s${STORM_NUM}/"

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0

