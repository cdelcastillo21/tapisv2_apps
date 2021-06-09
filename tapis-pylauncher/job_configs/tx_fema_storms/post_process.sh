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

if [ "$DEBUG" = true ] ; then
  set -x
fi

# Read command line inputs
NUM=$1

echo "STARTING POST-PROCESS FOR STORM ${NUM}"
pwd
date

RUN_DIR="./runs/s${NUM}"

# Make output DIR
OUT_DIR="./output/s${NUM}"
mkdir $OUT_DIR

# Create start timestamp file
START_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "${RUN_DIR}/ts_post_start_${START_TS}"

# Clean netcdf adcirc files - Put clean versions in output dir
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/fort.61.nc" "${OUT_DIR}/fort.61.nc"
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/fort.63.nc" "${OUT_DIR}/fort.63.nc"
ncks -O -x -v neta,nbdv,nvel,nbvv "${RUN_DIR}/maxele.63.nc" "${OUT_DIR}/maxele.63.nc"

# Move log files 

# Remove Parallel Processing Dirs
# rmdir -rf $RUN_DIR

# Create adcprep done timestamp file
STOP_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "${OUT_DIR}/ts_post_stop_${STOP_TS}"

echo "FINISHING POST-PROCESS FOR STORM ${NUM}"

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0

