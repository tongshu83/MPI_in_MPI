
$ mkdir ~/project/MPI_in_MPI/t7810/korvo-build
$ cd ~/project/MPI_in_MPI/t7810/korvo-build

Download korvo
$ wget –q https://gtkorvo.github.io/korvo_bootstrap.pl

$ mkdir ~/project/MPI_in_MPI/t7810/korvo-build/korvo

Set korvo
$ perl ./korvo_bootstrap.pl -i
Installed fresh ./korvo_build.pl
Installed fresh ./korvo_tag_db
Installed fresh ./korvo_arch
Installed fresh ./build_config
Specify version tag to use [stable] :
Specify install directory [\$HOME] : [Set install directory]
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


$ perl ./korvo_build.pl

Set environment variables
$ export KORVO_HOME=$HOME/project/MPI_in_MPI/t7810/korvo-build/korvo [adios install directory]
$ export PATH=$KORVO_HOME/bin:$PATH
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KORVO_HOME/lib [korvo lib path]

