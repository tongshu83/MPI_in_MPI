#!/bin/sh
set -eu

# RUN
# Runs the MELA DEAP workflow

PROCS=${PROCS:-3}

THIS=$( cd $( dirname $0 ); /bin/pwd )
export T_PROJECT_ROOT=$( cd $THIS/.. ; /bin/pwd )
EQP=$T_PROJECT_ROOT/ext/EQ-Py

export PYTHONPATH=$T_PROJECT_ROOT/python:$EQP
# Python packages can be installed and accessed from Swift/T as expected. You can also set the environment variable PYTHONPATH as desired, this will be picked up by the Swift/T features.

export TURBINE_RESIDENT_WORK_WORKERS=1
# Number of workers of this type

stc -p -I $EQP -r $EQP $T_PROJECT_ROOT/swift/workflow.swift
turbine -n $PROCS $T_PROJECT_ROOT/swift/workflow.tic $*

#swift-t -n $PROCS -p -I $EQP -r $EQP $T_PROJECT_ROOT/swift/workflow.swift $*

