
Download ADIOS
$ wget https://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz

Set environment variable
$ export LIBS=-pthread

$ ./configure --prefix=[adios install directory] --with-flexpath=[korvo install directory]
$ make
$ make install

Set environment variables
$ export ADIOS_HOME=[adios install directory]
$ export PATH=$ADIOS_HOME/bin:$PATH

