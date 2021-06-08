#!/bin/bash

# Read command line inputs
UPDATE_INT=$1

# Load necessary modules
module load python3 netcdf hdf5 nco
module list
pwd
date

JOB_DIR=$(pwd)

# Set proper conda env
source ~/miniconda3/etc/profile.d/conda.sh
conda activate aps
export PYTHONPATH=$CONDA_PREFIX/bin

# Launch data processing script
# python process_data.py ${JOB_DIR} -u ${UPDATE_INT} -lf data_process.log -ll DEBUG
python process_data.py ${JOB_DIR} -u ${UPDATE_INT} -ll DEBUG -lf data_process.log

exit 0
