#!/bin/bash -l

echo
echo "Setup and rebuild Swift/T with Python and R ..."
echo

if (( ${#ROOT} == 0  ))
then
	echo "Set ROOT as the parent installation directory!"
	exit 1
fi

set -eu

# Setup Swift/T
cd swift-t
PYTHON_EXE=$( which python )
sed -i 's/^ENABLE_PYTHON=0/ENABLE_PYTHON=1/' dev/build/swift-t-settings.sh
sed -i 's@^PYTHON_EXE=.*$@PYTHON_EXE='"$PYTHON_EXE"'@' dev/build/swift-t-settings.sh
R_VERSION=$( R --version | grep "R version" | cut -d' ' -f 3 )
sed -i 's/^ENABLE_R=0$/ENABLE_R=1/' dev/build/swift-t-settings.sh
sed -i 's@^.*R_INSTALL=.*$@R_INSTALL='"$ROOT"'/R-'"$R_VERSION"'/lib64/R@' dev/build/swift-t-settings.sh
sed -i 's@^.*RCPP_INSTALL=.*$@RCPP_INSTALL='"$ROOT"'/R-'"$R_VERSION"'/lib64/R/library/Rcpp@' dev/build/swift-t-settings.sh
sed -i 's@^.*RINSIDE_INSTALL=.*$@RINSIDE_INSTALL='"$ROOT"'/R-'"$R_VERSION"'/lib64/R/library/RInside@' dev/build/swift-t-settings.sh

# Rebuild Swift/T
dev/build/build-swift-t.sh
cd ..

echo
echo "Swift/T with Python and R is done!"
echo

