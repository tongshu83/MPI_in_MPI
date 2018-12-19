#!/bin/bash -l

echo
echo "RBFOpt starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ -d $ROOT ]
then
	rm -rf $ROOT/Bonmin-1.8.6
else
	echo "There does not exist $ROOT!"
	exit 1
fi

set -eu

echo
echo "Download and install BLAS ..."
echo
rm -fv blas-3.8.0.tgz
if wget -q http://www.netlib.org/blas/blas-3.8.0.tgz
then
	echo WARNING: wget exited with: $?
fi
rm -rf BLAS-3.8.0
tar -zxvf blas-3.8.0.tgz
cd BLAS-3.8.0/
gfortran -c -O3 -fPIC *.f
mkdir lib
ar rv lib/libblas.a *.o
gfortran -shared -o lib/libblas.so *.o
cd ..
source env_blas.sh
# export BLAS_HOME=$PWD/BLAS-3.8.0
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BLAS_HOME/lib


echo
echo "Download and install Bonmin ..."
echo
rm -fv Bonmin-1.8.6.tgz
if wget -q https://www.coin-or.org/Tarballs/Bonmin/Bonmin-1.8.6.tgz
then
	echo WARNING: wget exited with: $?
fi
rm -rf Bonmin-1.8.6
tar -zxvf Bonmin-1.8.6.tgz
cd Bonmin-1.8.6
./configure --prefix=$ROOT/Bonmin-1.8.6 --with-blas="-L$BLAS_HOME/lib -lblas"
make -j 8
make install
cd ..
source env_bonmin.sh
# export BONMIN_HOME=$ROOT/Bonmin-1.8.6
# export PATH=$BONMIN_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BONMIN_HOME/lib


echo
echo "Install RBFOpt ..."
echo
pip install rbfopt
pip install numpydoc

echo
echo "Test RBFOpt ..."
echo
rbfopt_test_interface.py --minlp_solver_path="$BONMIN_HOME/bin/cbc" branin
rbfopt_test_interface.py --minlp_solver_path="$BONMIN_HOME/bin/clp" branin
python example.py


echo
echo "RBFOpt is done!"
echo

