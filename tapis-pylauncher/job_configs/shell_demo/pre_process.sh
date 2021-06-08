#!/bin/bash

# Read command line inputs
RUN_NAME=$1
ADCIRC_RUN_PROC=$2

# Load necessary modules
module load python3 pylauncher netcdf/4.3.3.1 hdf5/1.8.16
module list
pwd
date

# Create Run Dir - Copy Base Inputs 
RUN_DIR="runs/run_${RUN_NAME}"
cp -r base_inputs $RUN_DIR

# Copy any override input files to run directory 
for file in inputs/${RUN_NAME}/*; do 
  if [ -f "$file" ]; then 
    b=$(basename $file)
    cp "$file" "${RUN_DIR}"/"$b"
  fi 
done

cd $RUN_DIR

# Copy adcprep executables to run directory 
cp ../../execs/adcprep . 

# Create start timestamp file
START_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "ts_start_${START_TS}"

# Run ADCPREP
printf '%s\n1\nfort.14\n' "$ADCIRC_RUN_PROC" | adcprep > prep.log
printf '%s\n2\n' "$ADCIRC_RUN_PROC" | adcprep >> prep.log

# Create adcprep done timestamp file
ADCPREP_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "ts_adcprep_${ADCPREP_TS}"

exit 0
