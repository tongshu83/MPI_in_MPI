#!/usr/bin/bash -l

set -eu

ENV_SH=env-bmpibash.sh
echo "#!/usr/bin/bash -l" > $ENV_SH
echo "" >> $ENV_SH
echo "set -a" >> $ENV_SH
echo "" >> $ENV_SH

./load-modules.sh
echo "./load-modules.sh" >> $ENV_SH
echo "" >> $ENV_SH

echo
echo "MPI-Bash starts ..."
echo

export ROOT=$PWD/install
echo "ROOT=$ROOT"
if (( ${#ROOT} == 0 ))
then
	echo "Set ROOT as the parent installation directory!!"
	exit 1
else
	if [ ! -d $ROOT ]
	then
		mkdir -pv $ROOT
	fi
fi
echo "export ROOT=$ROOT" >> $ENV_SH
export DIR=$PWD

if wget -q https://ftp.gnu.org/gnu/bash/bash-5.0-beta.tar.gz
then
	echo WARNING: wget exited with: $?
fi
if [ -d bash-5.0-beta ]
then
	rm -rf bash-5.0-beta
fi
tar -zxvf bash-5.0-beta.tar.gz

cd bash-5.0-beta
if [ -d $ROOT ]
then
	mkdir -pv $ROOT/bash-5.0-beta
else
	echo "There does not exist $ROOT!"
	exit 1
fi
./configure --prefix=$ROOT/bash-5.0-beta
make -j 8
make install
cd ..
source env-bash.sh
echo "source env-bash.sh" >> $ENV_SH
# export BASH_HOME=$ROOT/bash-5.0-beta
# export PATH=$BASH_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$BASH_HOME/lib:$LD_LIBRARY_PATH

echo
echo "Delete and then download MPI-Bash ..."
if [ -d MPI-Bash ]
then
	rm -rf MPI-Bash
fi
git clone https://github.com/jmjwozniak/MPI-Bash.git
cd MPI-Bash
autoreconf -fvi
if [ -d $ROOT ]
then
	mkdir -pv $ROOT/mpibash
else
	echo "There does not exist $ROOT!"
	exit 1
fi
./configure --with-bashdir=$DIR/bash-5.0-beta --prefix=$ROOT/mpibash CC=mpicc
make -j 8
make install
cd ..
source env-mpibash.sh
echo "source env-mpibash.sh" >> $ENV_SH
# export MPIBASH_HOME=$ROOT/mpibash
# export PATH=$MPIBASH_HOME/bin:$PATH
# export LD_LIBRARY_PATH=$MPIBASH_HOME/libexec/mpibash:$LD_LIBRARY_PATH

echo
echo "MPI-Bash is done."
echo

