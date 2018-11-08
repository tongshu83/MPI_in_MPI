#!/usr/bin/bash

set -eu

# This loads all modules for all builds for consistency
echo
echo Loading modules...
echo

module unload intel-mkl/2017.3.196-v7uuj6z
# module load gcc/7.1.0
module load intel/17.0.4-74uvhji
module load intel-mpi/2017.3-dfphq6k
# module load libpsm2/10.3-17
module load libtool/2.4.6-ikwuey2

echo
echo Modules OK
echo

