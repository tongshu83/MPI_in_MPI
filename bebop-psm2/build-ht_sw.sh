#!/bin/bash -l

set -eu

# Download Example-Heat_Transfer
if [ -d Example-Heat_Transfer ]
then
        rm -rv Example-Heat_Transfer
fi
git clone https://github.com/CODARcode/Example-Heat_Transfer.git

# Build heat trasfer
cd Example-Heat_Transfer
sed -i 's/^CC=cc$/CC=mpicc #cc/' Makefile
sed -i 's/^FC=ftn$/FC=mpif90 #ftn/' Makefile
make

# Build stage write
cd stage_write
sed -i 's/^CC=cc$/CC=mpicc #cc/' Makefile
sed -i 's/^FC=ftn$/FC=mpif90 #ftn/' Makefile
make

# Testing
cd ..
mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5 &
mpiexec -n 3 ./stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""

