#!/bin/bash

NUM_STEPS=$1
METHOD=$2
FILE=$3

export PWD=$( cd $( dirname $0 ) ; /bin/pwd )
sed -i 's/^dump 1 all custom\/adios_staging .* dump.bp id type x y z vx vy vz fx fy fy fz$/dump 1 all custom\/adios_staging '"$NUM_STEPS"' dump.bp id type x y z vx vy vz fx fy fy fz/' $FILE
sed -i 's/^dump_modify 1 format line "method=.*;have_metadata_file=0"$/dump_modify 1 format line "method='"$METHOD"';have_metadata_file=0"/' $FILE

