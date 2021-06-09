#!/bin/bash
# 
# TX FEMA STORM RUNS - Setup Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Basic set up required before running all job runs.
# Create run and output directories

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

mkdir -p runs                        # active job runs 
mkdir -p outputs                     # output files for each storm
mkdir -p storms                      # links to storm wind/press files go here
mkdir -p mesh                        # adcirc files common to all runs go here

# These are the hard-coded directories where the actual wind data and mesh data resides
# Note these are in scratch not in corral, since execution nodes can't access corral. 
# They have been pre-staged prior to running this from within Stampede2 using rsync. 
STORM_DATA_DIR="/scratch/06307/clos21/TX_FEMA_Storms/winds"
MESH_DATA_DIR="/scratch/06307/clos21/TX_FEMA_Storms/mesh"
EXECS_DIR="/scratch/06307/clos21/TX_FEMA_Storms/execs/v55.00/stampede2"

cd storms
ln -s "${STORM_DATA_DIR}/*" .

cd ../mesh
ln -s "${MESH_DATA_DIR}/*" .

cd ..
ln -s "${EXECS_DIR}/*" . 

# Make shell scripts executable in job config dir 
chmod +x job_configs/*.sh

# Symbolically link shell scripts and adcirc executables to root job directory 
ln -s ./job_configs/pre_process.sh .
ln -s ./job_configs/post_process.sh .
ln -s ./job_configs/adcprep .
ln -s ./job_configs/padcirc .

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
