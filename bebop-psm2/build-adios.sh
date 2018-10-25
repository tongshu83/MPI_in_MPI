#!/bin/bash -l

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT!"
	exit 1
fi

if [ -d $ROOT ]
then
	mkdir $ROOT/adios
fi

set -eu

# Download ADIOS
if wget -q https://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz
then
	echo WARNING: wget exited with: $?
fi
if [ -d adios-1.13.1 ]
then
	rm -rv adios-1.13.1
fi
tar -zxvf adios-1.13.1.tar.gz

export LIBS=-pthread

cd adios-1.13.1
./configure --prefix=$ROOT/adios --with-flexpath=$ROOT/korvo CFLAGS="-g -O2 -fPIC" CXXFLAGS="-g -O2 -fPIC" FCFLAGS="-g -O2 -fPIC"
make -j 8
make install

export ADIOS_HOME=$ROOT/adios
export PATH=$ADIOS_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ADIOS_HOME/lib

cd ..

