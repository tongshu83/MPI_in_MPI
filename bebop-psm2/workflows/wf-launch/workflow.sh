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

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=4
export PPN=1
export WALLTIME=00:01:00

MACHINE="-m slurm" # -m (machine) option that accepts pbs, cobalt, cray, lsf, theta, or slurm. The empty string means the local machine.

ENVS="" # "-e <key>=<value>" Set an environment variable in the job environment.

set -x
stc -p -u $WORKFLOW_ROOT/$WORKFLOW_SWIFT
# -p: Disable the C preprocessor
# -u: Only compile if target is not up-to-date

turbine -l $MACHINE -n $PROCS $ENVS $WORKFLOW_ROOT/$WORKFLOW_TIC
# -l: Enable mpiexec -l ranked output formatting
# -n <procs>: The total number of Turbine MPI processes

#swift-t -l $MACHINE -p -n $PROCS $ENVS $WORKFLOW_ROOT/workflow.swift

echo WORKFLOW COMPLETE.

