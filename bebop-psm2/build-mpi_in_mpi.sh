#!/bin/bash -l

echo
echo "MPI in MPI starts ..."
echo

set -eu

if [ ! -d MPI ]
then
	echo "Missing MPI!"
	exit 1
fi
echo
echo "Build a single MPI ..."
cd MPI
make clean
make
mkdir -pv MPI/experiment

echo
echo "Build MPI_in_MPI ..."
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

mkdir -pv experiment
cd experiment
rm -f heat_transfer.xml
ln -s ../Example-Heat_Transfer/heat_transfer.xml heat_transfer.xml
rm -f in.quench in.quench.short restart.liquid CuZr.fs
ln -s ../Example-LAMMPS/swift-all/in.quench in.quench
ln -s ../Example-LAMMPS/swift-all/in.quench.short in.quench.short
ln -s ../Example-LAMMPS/swift-all/restart.liquid restart.liquid
ln -s ../Example-LAMMPS/swift-all/CuZr.fs CuZr.fs

cd ..

echo
echo "MPI in MPI is done!"
echo

