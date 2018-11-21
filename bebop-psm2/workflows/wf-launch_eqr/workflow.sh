#!/bin/bash
set -eu

# WORKFLOW SH
# Main user entry point

if [[ ${#} != 2 ]]
then
	echo "Usage: ./workflow.sh workflow_name experiment_id"
	exit 1
fi

WORKFLOW_SWIFT=$1.swift
WORKFLOW_TIC=${WORKFLOW_SWIFT%.swift}.tic

export EXPID=$2

# Turn off Swift/T debugging
export TURBINE_LOG=0 TURBINE_DEBUG=0 ADLB_DEBUG=0

# Find the directory of ./workflow.sh
export WORKFLOW_ROOT=$( cd $( dirname $0 ) ; /bin/pwd )
cd $WORKFLOW_ROOT

# Set the output directory
export TURBINE_OUTPUT=$WORKFLOW_ROOT/experiment/$EXPID
mkdir -pv $TURBINE_OUTPUT
cp -f $WORKFLOW_ROOT/get_maxtime.sh $TURBINE_OUTPUT/get_maxtime.sh

if [[ $1 = "workflow-ht" ]]
then
	cd $TURBINE_OUTPUT
	ln -s ../heat_transfer.xml heat_transfer.xml
	cd -
fi

if [[ $1 = "workflow-lmp" ]]
then
	cd $TURBINE_OUTPUT
	ln -s ../in.quench in.quench
	ln -s ../in.quench.short in.quench.short
	ln -s ../restart.liquid restart.liquid
	ln -s ../CuZr.fs CuZr.fs
	cd -
fi

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=8
export PPN=1
export WALLTIME=00:01:00

MACHINE="-m slurm" # -m (machine) option that accepts pbs, cobalt, cray, lsf, theta, or slurm. The empty string means the local machine.

# EMEWS resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

PYTHON_EXE=$( which python )
export PYTHONPATH=${PYTHON_EXE/bin\/python/lib\/python2.7}

# USER: set the R variable to your R installation
# R=$HOME/project/bebop/MPI_in_MPI/bebop-psm2/install/R-3.5.1/lib64/R
R=$R_HOME
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R/lib:$R/library/Rcpp/libs:$R/library/RInside/lib:$R/library/RInside/libs

EQR=$EQR_HOME
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EQR

# mlrMBO settings
if [[ $1 = "workflow-sh" || $1 = "workflow-mpi" ]]
then
	PARAM_SET_FILE=$WORKFLOW_ROOT/data/params-mpi.R
fi
if [[ $1 = "workflow-ht" ]]
then
	PARAM_SET_FILE=$WORKFLOW_ROOT/data/params-ht.R
fi
if [[ $1 = "workflow-lmp" ]]
then
	PARAM_SET_FILE=$WORKFLOW_ROOT/data/params-lmp.R
fi
MAX_ITERATIONS=2
MAX_CONCURRENT_EVALUATIONS=2

# Construct the command line given to Swift/T
CMD_LINE_ARGS=( -param_set_file=$PARAM_SET_FILE
		-it=$MAX_ITERATIONS
		-pp=$MAX_CONCURRENT_EVALUATIONS
	)

ENVS="-e LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R/lib:$R/library/Rcpp/libs:$R/library/RInside/lib:$R/library/RInside/libs:$EQR -e R=$R_HOME -e EQR=$EQR_HOME"
# "-e <key>=<value>" Set an environment variable in the job environment.

set -x
stc -p -u -I $EQR -r $EQR $WORKFLOW_ROOT/$WORKFLOW_SWIFT
# -p: Disable the C preprocessor
# -u: Only compile if target is not up-to-date
# -I: Add a directory to the import and include search path.

turbine -l $MACHINE -n $PROCS $ENVS $WORKFLOW_ROOT/$WORKFLOW_TIC ${CMD_LINE_ARGS[@]}
# -l: Enable mpiexec -l ranked output formatting
# -n <procs>: The total number of Turbine MPI processes

# swift-t -p -l $MACHINE -n $PROCS -I $EQR -r $EQR $ENVS $WORKFLOW_ROOT/$WORKFLOW_SWIFT ${CMD_LINE_ARGS[@]}

echo WORKFLOW COMPLETE.

