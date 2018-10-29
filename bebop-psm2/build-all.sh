#!/bin/bash -l

set -a
export ROOT=$PWD/install
if [ ! -d $ROOT ]
then
	mkdir $ROOT
fi

source build-korvo.sh
source build-adios.sh
source build-ht_sw.sh
source build-swiftT.sh 
source build-lammps.sh
source build-mpi_in_mpi.sh

