#!/bin/bash

# Read command line inputs
RUN_NAME=$1

# Load necessary modules
module load python3 pylauncher netcdf/4.3.3.1 hdf5/1.8.16
module list
pwd
date

RUN_DIR="runs/run_${RUN_NAME}"

# Remove Parallel Processing Dirs
# rmdir -rf $RUN_DIR/PE*

# Create padcirc done timestamp file
PADCIRC_TS=`date +"%Y-%m-%d-%H:%M:%S"`
touch "${RUN_DIR}/ts_padcirc_${PADCIRC_TS}"

exit 0
