
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2

Download ADIOS
$ wget https://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz
$ tar -zxvf adios-1.13.1.tar.gz
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/adios-1.13.1
$ mkdir ~/project/bebop/MPI_in_MPI/bebop-psm2/adios-1.13.1/adios

Set environment variable
$ export LIBS=-pthread

$ ./configure --prefix=/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/adios-1.13.1/adios [adios install directory] --with-flexpath=/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/korvo-build/korvo [korvo install directory] CFLAGS="-g -O2 -fPIC" CXXFLAGS="-g -O2 -fPIC" FCFLAGS="-g -O2 -fPIC"
$ make -j 8
$ make install

Set environment variables
$ export ADIOS_HOME=$HOME/project/bebop/MPI_in_MPI/bebop-psm2/adios-1.13.1/adios [adios install directory]
$ export PATH=$ADIOS_HOME/bin:$PATH
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ADIOS_HOME/lib

