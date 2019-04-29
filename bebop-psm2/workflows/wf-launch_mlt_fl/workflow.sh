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
	cp -f ../conf_hs_smpls2.csv conf_hs_smpls2.csv
	cp -f ../conf_hs_smpls3.csv conf_hs_smpls3.csv
	cp -f ../heat_transfer.xml heat_transfer.xml
	cd -
fi

if [[ $1 = "workflow-ht-in" ]]
then
	cd $TURBINE_OUTPUT
	cp -f ../conf_hs_in_smpls.csv conf_hs_in_smpls.csv
	cp -f ../heat_transfer.xml heat_transfer.xml
	cd -
fi

if [[ $1 = "workflow-lmp" ]]
then
	cd $TURBINE_OUTPUT
#	cp -f ../prdct_lmp_voro.csv prdct_lmp_voro.csv
#	cp -f ../prdct_lv.csv prdct_lv.csv
#	cp -f ../prdct_l_v_lv.csv prdct_l_v_lv.csv
#	cp -f ../prdct_lv_lv.csv prdct_lv_lv.csv
#	cp -f ../prdct_lvp_lv.csv prdct_lvp_lv.csv
#	cp -f ../prdct_lvm_lv.csv prdct_lvm_lv.csv
	cp -f ../conf_lv_smpls.csv conf_lv_smpls.csv
	cp -f ../in.quench in.quench
	cp -f ../restart.liquid restart.liquid
	cp -f ../CuZr.fs CuZr.fs
	cd -
fi

if [[ $1 = "workflow-lmp-in" ]]
then
	cd $TURBINE_OUTPUT
	cp -f ../conf_lv_in_smpls.csv conf_lv_in_smpls.csv
	cp -f ../in.quench in.quench
	cp -f ../restart.liquid restart.liquid
	cp -f ../CuZr.fs CuZr.fs
	cd -
fi

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=66
export PPN=1
export WALLTIME=24:00:00
export PROJECT=PACC
export QUEUE=bdw

MACHINE="-m slurm" # -m (machine) option that accepts pbs, cobalt, cray, lsf, theta, or slurm. The empty string means the local machine.

ENVS="" # "-e <key>=<value>" Set an environment variable in the job environment.

set -x
stc -p -O0 $WORKFLOW_ROOT/$WORKFLOW_SWIFT
# -p: Disable the C preprocessor
# -u: Only compile if target is not up-to-date

turbine -l $MACHINE -n $PROCS $ENVS $WORKFLOW_ROOT/$WORKFLOW_TIC
# -l: Enable mpiexec -l ranked output formatting
# -n <procs>: The total number of Turbine MPI processes

#swift-t -l $MACHINE -p -n $PROCS $ENVS $WORKFLOW_ROOT/workflow.swift

echo WORKFLOW COMPLETE.

