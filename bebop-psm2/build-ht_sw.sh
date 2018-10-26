#!/bin/bash -l

set -eu

# Download Example-Heat_Transfer
if [ -d Example-Heat_Transfer ]
then
	rm -rf Example-Heat_Transfer
fi
git clone https://github.com/CODARcode/Example-Heat_Transfer.git

# Build heat transfer
cd Example-Heat_Transfer
sed -i 's/^CC=cc$/CC=mpicc #cc/' Makefile
sed -i 's/^FC=ftn$/FC=mpif90 #ftn/' Makefile
echo
echo "Build heat transfer ..."
make

# Build stage write
cd stage_write
sed -i 's/^CC=cc$/CC=mpicc #cc/' Makefile
sed -i 's/^FC=ftn$/FC=mpif90 #ftn/' Makefile
echo
echo "Build stage write ..."
make

# Testing
cd ..
echo
echo "Testing Heat_Transfer ..."
mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5 &
mpiexec -n 3 ./stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""

if [ ! -d experiment ]
then
        mkdir experiment
fi
cd experiment
rm -f heat_transfer.xml
ln -s ../heat_transfer.xml heat_transfer.xml
cd ..
cp -f ../sbatch-bebop-ht.sh sbatch-bebop-ht.sh

cd ..

