#!/bin/bash -l

set -a
export ROOT=$HOME/Public/sfw/bebop/codar-install
mkdir -pv $ROOT

BUILD_LOG=build-$( date "+%Y-%m-%d-%H:%M_%p" ).log

{
echo ROOT=$ROOT
echo
source modules.sh
source build-korvo.sh
# source env_korvo.sh
source build-adios.sh
# source env_adios.sh
source build-ht_sw.sh
source build-swiftT.sh
# source env_swiftT.sh
source build-lammps.sh
source build-mpi_in_mpi.sh
} 2>& 1 | tee $BUILD_LOG

