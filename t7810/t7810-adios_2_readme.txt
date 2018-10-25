
cd ~/project/MPI_in_MPI/t7810

# Download ADIOS
wget https://users.nccs.gov/~pnorbert/adios-1.13.1.tar.gz
tar -zxvf adios-1.13.1.tar.gz
mkdir ~/project/MPI_in_MPI/t7810/adios-1.13.1/adios

# Set environment variable
export LIBS=-pthread

# Build ADIOS
cd ~/project/MPI_in_MPI/t7810/adios-1.13.1
./configure --prefix=$HOME/project/MPI_in_MPI/t7810/adios-1.13.1/adios --with-flexpath=$HOME/project/MPI_in_MPI/t7810/korvo-build/korvo CFLAGS="-g -O2 -fPIC" CXXFLAGS="-g -O2 -fPIC" FCFLAGS="-g -O2 -fPIC"
make -j 8
make install

# Set environment variables
export ADIOS_HOME=$HOME/project/MPI_in_MPI/t7810/adios-1.13.1/adios
export PATH=$ADIOS_HOME/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ADIOS_HOME/lib

