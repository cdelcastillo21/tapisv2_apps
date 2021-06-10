#!/bin/bash
# 
# TX FEMA STORM RUNS - Setup Script
# Carlos del-Castillo-Negrete - cdelcastillo21@gmail.com
# June 2021
#
# Basic set up required before running all job runs.
# Create run and output directories, directories where storm and mehs data will be linked to
# Note that the storm and mesh files are staged in a scratch directory that is shared via the 
# unix file system with everyone so that the execution node can access it. This is to avoid copying
# large amounts of data until needed to. 

DEBUG=true

if [ "$DEBUG" = true ] ; then
  set -x
fi

echo "STARTING SETUP"
pwd
date

mkdir -p runs                             # active job runs 
mkdir -p outputs/runs                     # output files for each storm run
mkdir -p logs/runs                        # log files for each storm run
mkdir -p storms                           # links to storm wind/press files go here
mkdir -p mesh                             # adcirc files common to all runs go here

# These are the hard-coded directories where the actual wind data and mesh data resides
# Note these are in scratch not in corral, since execution nodes can't access corral. 
# They have been pre-staged prior to running this from within Stampede2 using rsync. 
STORM_DATA_DIR="/scratch/06307/clos21/TX_FEMA_Storms/winds"
MESH_DATA_DIR="/scratch/06307/clos21/TX_FEMA_Stos/test_mesh"
EXECS_DIR="/scratch/06307/clos21/TX_FEMA_Storms/execs/v55.00/stampede2"

cd storms
ln -s $STORM_DATA_DIR/* .

cd ../mesh
ln -s $MESH_DATA_DIR/* .

cd ..
ln -s $EXECS_DIR/* .

# Make scripts executable in job config dir 
chmod +x pre_process.sh post_process.sh 

if [ "$DEBUG" = true ] ; then
  set +x
fi

exit 0
