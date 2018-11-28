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
	mkdir -pv $ROOT/R-3.4.3
else 
	echo "There does not exist $ROOT!"
	exit 1
fi

# echo "Loading Modules ..."
# module load python/2.7.15-b5bimol
# module load readline/7.0-3qkdfwk
# module load bzip2/1.0.6-hcvyuh5
# module load xz/5.2.4-okshegf
# module load curl/7.60.0-6ldg322
# module load libxml2/2.9.8-eqqbnqd
# echo "Modules are loaded!"

set -eu

echo
echo "Download and install R ..."
echo

# Download R
if [ -f R-3.4.3.tar.gz ]
then
	rm -fv R-3.4.3.tar.gz
fi
if wget -q https://cran.r-project.org/src/base/R-3/R-3.4.3.tar.gz
# if wget -q https://cran.r-project.org/src/base/R-3/R-3.4.4.tar.gz
then
	echo WARNING: wget exited with: $?
fi
tar -zxvf R-3.4.3.tar.gz
cd R-3.4.3
./configure --prefix=$ROOT/R-3.4.3 --without-ICU --enable-R-shlib
make -j 8
make install
source ./env_R.sh
# export R_HOME=$ROOT/R-3.4.3/lib64/R
# export PATH=$R_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib


echo
echo "Install mlrMBO ..."
echo
./install-mlrMBO.sh


echo
echo "R is done!"
echo

