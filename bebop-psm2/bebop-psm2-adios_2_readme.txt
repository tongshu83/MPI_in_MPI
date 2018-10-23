
Download ADIOS
$ wget https://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz

Set environment variable
$ export LIBS=-pthread

$ ./configure --prefix=[adios install directory] --with-flexpath=[korvo install directory] CFLAGS="-g -O2 -fPIC" CXXFLAGS="-g -O2 -fPIC" FCFLAGS="-g -O2 -fPIC"
$ make
$ make install

Set environment variables
$ export ADIOS_HOME=[adios install directory]
$ export PATH=$ADIOS_HOME/bin:$PATH

