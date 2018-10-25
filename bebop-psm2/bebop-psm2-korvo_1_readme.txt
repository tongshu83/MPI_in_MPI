
Load modules gcc/7.1.0, libpsm2/10.3-17, and cmake/3.9.4-3tixtqt
$ module unload intel-mkl/2017.3.196-v7uuj6z
$ module load gcc/7.1.0
$ module load libpsm2/10.3-17
$ module load cmake/3.9.4-3tixtqt

$ mkdir ~/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build

Download korvo
$ wget –q https://gtkorvo.github.io/korvo_bootstrap.pl

$ mkdir ~/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build/korvo

Set korvo
$ perl ./korvo_bootstrap.pl -i
Installed fresh ./korvo_build.pl
Installed fresh ./korvo_tag_db
Installed fresh ./korvo_arch
Installed fresh ./build_config
Specify version tag to use [stable] :
Specify install directory [\$HOME] : /home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build/korvo [Set install directory]
Configuring system for release "stable", install directory "[install directory]"

Edit korvo_build_config
$ vi korvo_build_config
...
% DISABLE_TESTING
...

In korvo_build_config
# Generate dynamic libraries (used by LAMMPS)
Line 52: korvogithub configure
Line 53: korvogithub cmake

# Generate static libraries (used by ADIOS)
Line 52: korvogithub configure --disable-shared
Line 53: korvogithub cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DTARGET_CNL=1 -DPKG_CONFIG_EXECUTABLE=IGNORE

Compile twice based on different configuration, and combine the two kinds of libraries


$ perl ./korvo_build.pl

Set environment variables
$ export KORVO_HOME=$HOME/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build/korvo [adios install directory]
$ export PATH=$KORVO_HOME/bin:$PATH
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KORVO_HOME/lib

