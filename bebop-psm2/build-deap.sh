#!/bin/bash -l

echo
echo "DEAP starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ -d $ROOT ]
then
	mkdir -pv $ROOT/Python-2.7.15
else 
	echo "There does not exist $ROOT!"
	exit 1
fi

set -eu

echo
echo "Download and install Python ..."
echo

# Download Python
if [ -d Python-2.7.15 ]
then
	rm -rf Python-2.7.15
fi
if wget -q https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
then
	echo WARNING: wget exited with: $?
fi
tar -zxvf Python-2.7.15.tgz
cd Python-2.7.15
./configure --prefix=$ROOT/Python-2.7.15 --enable-shared --enable-optimizations
make -j 8
make install
cd ..
source ./env_py.sh
# export PYTHON_HOME=$ROOT/Python-2.7.15
# export PATH=$PYTHON_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PYTHON_HOME/lib


# echo
# echo "Install PIP ..."
# echo
# curl https://bootstrap.pypa.io/get-pip.py -o Python-2.7.15/get-pip.py
# python Python-2.7.15/get-pip.py

echo
echo "Install DEAP ..."
echo
pip install git+https://github.com/DEAP/deap@master


echo
echo "Test DEAP ..."
echo
if [ -d deap ]
then
        rm -rf deap
fi
git clone https://github.com/DEAP/deap.git
# python deap/setup.py install
python deap/examples/ga/onemax.py


echo
echo "DEAP is done!"
echo

