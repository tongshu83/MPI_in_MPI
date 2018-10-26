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
make clean
make

if [ ! -d Example-Heat_Transfer ]
then
        echo "Missing Example-Heat_Transfer!"
	exit 1
fi
rm -f heat_transfer.xml
ln -s Example-Heat_Transfer/heat_transfer.xml heat_transfer.xml


if [ ! -d Example-LAMMPS ]
then
        echo "Missing Example-LAMMPS!"
        exit 1
fi
rm -f in.quench in.quench.short restart.liquid CuZr.fs
ln -s Example-LAMMPS/swift-all/in.quench in.quench
ln -s Example-LAMMPS/swift-all/in.quench.short in.quench.short
ln -s Example-LAMMPS/swift-all/restart.liquid restart.liquid
ln -s Example-LAMMPS/swift-all/CuZr.fs CuZr.fs

if [ ! -d experiment ]
then
	mkdir experiment
fi
cd experiment
rm -f heat_transfer.xml
ln -s ../Example-Heat_Transfer/heat_transfer.xml heat_transfer.xml
rm -f in.quench in.quench.short restart.liquid CuZr.fs
ln -s ../Example-LAMMPS/swift-all/in.quench in.quench
ln -s ../Example-LAMMPS/swift-all/in.quench.short in.quench.short
ln -s ../Example-LAMMPS/swift-all/restart.liquid restart.liquid
ln -s ../Example-LAMMPS/swift-all/CuZr.fs CuZr.fs

cd ..

