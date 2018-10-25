
mkdir ~/project/MPI_in_MPI/t7810/korvo-build
cd ~/project/MPI_in_MPI/t7810/korvo-build

# Download korvo
wget –q https://gtkorvo.github.io/korvo_bootstrap.pl

mkdir ~/project/MPI_in_MPI/t7810/korvo-build/korvo

# Set korvo
perl ./korvo_bootstrap.pl stable $HOME/project/MPI_in_MPI/t7810/korvo-build/korvo
# $ perl ./korvo_bootstrap.pl -i


# Edit korvo_build_config
# First, generate static libraries below (used by ADIOS)
# Line 52: korvogithub configure --disable-shared
# Line 53: korvogithub cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DTARGET_CNL=1 -DPKG_CONFIG_EXECUTABLE=IGNORE
# Then, generate dynamic libraries below (used by LAMMPS)
# Line 52: korvogithub configure
# Line 53: korvogithub cmake

sed -i 's/^korvogithub configure$/korvogithub configure --disable-shared/' korvo_build_config
sed -i 's/^korvogithub cmake$/korvogithub cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DTARGET_CNL=1 -DPKG_CONFIG_EXECUTABLE=IGNORE/' korvo_build_config
perl ./korvo_build.pl
rm -rf build_area build_results
sed -i 's/^korvogithub configure --disable-shared$/korvogithub configure/' korvo_build_config
sed -i 's/^korvogithub cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DTARGET_CNL=1 -DPKG_CONFIG_EXECUTABLE=IGNORE$/korvogithub cmake/' korvo_build_config
perl ./korvo_build.pl

# Set environment variables
export KORVO_HOME=$HOME/project/MPI_in_MPI/t7810/korvo-build/korvo
export PATH=$KORVO_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KORVO_HOME/lib

