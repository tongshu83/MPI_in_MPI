#!/bin/bash -l

echo
echo "DEAP starts ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

if [ ! -d $ROOT ]
then
	echo "There does not exist $ROOT!"
	exit 1
fi

set -eu


echo
echo "Install DEAP ..."
echo
pip install deap
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

#rm -rf emews
#mkdir emews
#cd emews
#git clone git@github.com:emews/mela.git
#git clone git@github.com:emews/EQ-Py.git
#EQ-Py/src/install mela/deap/ext/EQ-Py
#cd mela/deap
#swift/run --settings=swift/settings.json > run.log


echo
echo "DEAP is done!"
echo

