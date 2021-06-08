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

# Read command line inputs
NUM=$1
ADCIRC_RUN_PROC=$2

# Create Run Dir - Copy Base Inputs TODO: Check preservation of sym links?
RUN_DIR="./runs/s${NUM}"
cp -r --preserve=links ./mesh $RUN_DIR

# Copy wind and pressure files for strom to run directory 
cp --preserve=links "./storms/TEX_FEMA_RUN${NUM}.pre $RUN_DIR/fort.221"
cp --preserve=links "./storms/TEX_FEMA_RUN${NUM}.WND $RUN_DIR/fort.222"

cd $RUN_DIR

# Copy adcprep executables to run directory 
cp --preserve=links ../../adcprep . 

# Create start timestamp file
START_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "./ts_adcprep_start_${START_TS}"

# Run ADCPREP
printf '%s\n1\nfort.14\n' "$ADCIRC_RUN_PROC" | adcprep > prep.log
printf '%s\n2\n' "$ADCIRC_RUN_PROC" | adcprep >> prep.log

# Create adcprep done timestamp file
ADCPREP_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "./ts_adcprep_end_${ADCPREP_TS}"

exit 0
