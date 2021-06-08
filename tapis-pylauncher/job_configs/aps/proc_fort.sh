#!/bin/bash

# Read command line inputs
NUM=$1
F63=$2
CF63=$3
NCAP_STR_1=$4
NCAP_STR_2=$5
SAMPLE_NUM=$6

# Load necessary modules
module load python3 pylauncher netcdf/4.3.3.1 hdf5/1.8.16
module list
pwd
date

# Remove dimensions that cause issues with loading into xarray
ncks -O -x -v neta,nbdv,nvel,nbvv $F63 $CF63

# Add param values to netcdf file
ncap2 -O -s $NCAP_STR_1 $CF63 $CF63

# Add attribue to param vals indicating sample which is from
ncatted -O -a sample,p_vals,a,s,$NUM $CF63 $CF63

# Add job ts to netcdf file
ncap2 -O -s $NCAP_STR_2 $CF63 $CF63

