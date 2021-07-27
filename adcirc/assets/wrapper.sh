# General purpose adcirc runner. Executes adcprep first.
set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )
module load netcdf

# Run the script with the runtime values passed in from the job request

${AGAVE_JOB_CALLBACK_RUNNING}

mv ${inputDirectory}/* .
pwd
ls -l

# generate the two prep files
WRITE_PROC=${writeProcesses}

# Question, which of  these is correct for total node count?
CORES2=$(( ${AGAVE_JOB_PROCESSORS_PER_NODE} * ${AGAVE_JOB_NODE_COUNT} ))
CORES=${AGAVE_JOB_PROCESSORS_PER_NODE}
echo "Which correct? - ${CORES} vs ${CORES2}"
PCORES=$(( $CORES-$WRITE_PROC ))

echo "ADCIRC will run on a total of ${CORES} cores, ${PCORES} for computation, ${WRITE_PROC} for data otuput"

rm -rf in.prep1 in.prep2 &>/dev/null
cat << EOT >> in.prep1
$PCORES
1
fort.14
EOT

cat << EOT >> in.prep2
$PCORES
2
EOT

cat in.prep1
cat in.prep2

more in.prep1
more in.prep2

ls -l

# Copy default executables (in test folder) if not in inputs
if [ ! -f adcprep ]; then
  cp test/inputs/adcprep .
fi
if [ ! -f padcirc ]; then
  cp test/inputs/padcirc .
fi

# decompose the things
chmod +x adcprep
./adcprep < ./in.prep1 >> adcprep.eo.txt 2>&1
./adcprep < ./in.prep2 >> adcprep.eo.txt 2>&1

pwd

# run the things
#ibrun /work/projects/wma_apps/stampede2/adcirc/padcirc-52.00/padcirc >> output.eo.txt 2>&1
chmod +x padcirc 
ibrun -np $CORES ./padcirc -W $WRITE_PROC >> output.eo.txt 2>&1


if [ ! $? ]; then
	echo "ADCIRC exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi

exit 0
