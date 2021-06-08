#!/bin/bash

JOB_DIR=$1

cd $JOB_DIR

# Create scan inputs and outputs directory
mkdir -p inputs                      # Directory where inputs to scan through are
mkdir -p outputs                     # Global and specific output files 
mkdir -p out_data_configs            # Configs to extract datasets 
mkdir -p runs                        # Active job runs 

chmod +x *.sh

exit 0
