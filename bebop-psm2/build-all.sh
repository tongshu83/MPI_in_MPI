#!/bin/bash -l

set -a
export ROOT=$PWD/install
# export ROOT=$HOME/Public/sfw/bebop/codar-install
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
source build-conda2.sh
# source env_conda2.sh
#source build-R.sh
# source env_R.sh
source build-swiftT_PyR.sh
#source build-deap.sh
#source build-rbfopt.sh
# source env_blas.sh
# source env_bonmin.sh
} 2>& 1 | tee $BUILD_LOG

