#!/bin/bash
job_dir=$1
CORRAL_DIR="/gpfs/corral3/repl/projects/NHERI/projects/5832364376574324245-242ac116-0001-012/storms"
dest=${2:-$CORRAL_DIR}

result_dir=$job_dir/outputs/runs
cd $result_dir
chmod 777 s*
chmod 666 s*/*
if [ $dest == "$CORRAL_DIR" ]; then
    mkdir -p $dest/tmp
    for dir in s*; do
        echo "Copying $dir to a tmp dir on Corral"
        # We copy to a tmp dir because there is an issue where         
        cp -rp $dir $dest/tmp
    done
else
    cp -rp s* $dest
fi

