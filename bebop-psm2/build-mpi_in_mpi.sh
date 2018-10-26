#!/bin/bash -l

set -eu

if [ ! -d MPI ]
then
	echo "Missing MPI!"
	exit 1
fi
cd MPI
make clean
make
cd ..

if [ ! -d Example-Heat_Transfer ]
then
        echo "Missing Example-Heat_Transfer!"
	exit 1
fi
cd Example-Heat_Transfer
if [ ! -d experiment ]
then
        mkdir experiment
fi
cp -f heat_transfer.xml experiment/heat_transfer.xml
cd ..
cp -f sbatch-bebop-ht.sh Example-Heat_Transfer/sbatch-bebop-ht.sh

if [ ! -d experiment ]
then
	mkdir experiment
fi
cp -f Example-Heat_Transfer/heat_transfer.xml experiment/heat_transfer.xml
make clean
make

