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
export PROCS=4
export PPN=1
export WALLTIME=00:03:00

MACHINE="-m slurm" # -m (machine) option that accepts pbs, cobalt, cray, lsf, theta, or slurm. The empty string means the local machine.

ENVS="" # "-e <key>=<value>" Set an environment variable in the job environment.

set -x
stc -p -u -O0 $WORKFLOW_ROOT/$WORKFLOW_SWIFT
# -p: Disable the C preprocessor
# -u: Only compile if target is not up-to-date
# -O <Optimization level>: Set compiler optimization level: 0 - no optimizations; 1,2,3 - standard optimizations (DEFAULT) (this will change later)

turbine -l $MACHINE -n $PROCS $ENVS $WORKFLOW_ROOT/$WORKFLOW_TIC
# -l: Enable mpiexec -l ranked output formatting
# -n <procs>: The total number of Turbine MPI processes

#swift-t -l $MACHINE -p -n $PROCS $ENVS $WORKFLOW_ROOT/workflow.swift

echo WORKFLOW COMPLETE.

