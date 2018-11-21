#!/bin/bash -l

echo
echo "R starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ -d $ROOT ]
then
	mkdir -pv $ROOT/eqr
else
	echo "There does not exist $ROOT!"
	exit 1
fi

set -eu

echo
echo "Setup and install EQ-R ..."
echo

cd $ROOT/eqr
$ cp settings.template.sh settings.sh
# Edit settings.sh
# R_HOME=$HOME/project/bebop/MPI_in_MPI/bebop-psm2/install/R-3.5.1/lib64/R
# R_INCLUDE=$R_HOME/include
# R_LIB=$R_HOME/lib
# R_INSIDE=$R_HOME/library/RInside
# RCPP=$R_HOME/library/Rcpp
# 
# TCL_INCLUDE=/blues/gpfs/home/software/spack-0.10.1/opt/spack/linux-centos7-x86_64/intel-17.0.4/tcl-8.6.6-x4wnbsghrgh5akxryios5jfexnd4n75t/include
# TCL_LIB=/blues/gpfs/home/software/spack-0.10.1/opt/spack/linux-centos7-x86_64/intel-17.0.4/tcl-8.6.6-x4wnbsghrgh5akxryios5jfexnd4n75t/lib
# TCL_LIBRARY=tcl8.6

sed -i 's@^R_HOME=.*$@R_HOME='"$ROOT"'/R-3.5.1/lib64/R@' settings.sh
sed -i 's@^R_INCLUDE=.*$@R_INCLUDE=$R_HOME/include@' settings.sh
sed -i 's@^R_LIB=.*$@R_LIB=$R_HOME/lib@' settings.sh
sed -i 's@^R_INSIDE=.*$@R_INSIDE=$R_HOME/library/RInside@' settings.sh
sed -i 's@^RCPP=.*$@RCPP=$R_HOME/library/Rcpp@' settings.sh
TCLSH_EXE=$( which tclsh )
TCL_HOME=${TCLSH_EXE/\/bin\/tclsh/}
sed -i 's@^TCL_INCLUDE=.*$@TCL_INCLUDE='"$TCL_HOME"'/include@' settings.sh
sed -i 's@^TCL_LIB=.*$@TCL_LIB='"$TCL_HOME"'/lib@' settings.sh

source settings.sh
./bootstrap
./configure --prefix=$ROOT/eqr
make -j 8
make install
cd ..
source env_eqr.sh
# export EQR_HOME=$ROOT/eqr
# export PATH=$EQR_HOME:$PATH
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EQR_HOME

echo
echo "EQ-R is done!"
echo

