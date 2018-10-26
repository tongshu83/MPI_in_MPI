
Download Example-Heat_Transfer
$ git clone https://github.com/CODARcode/Example-Heat_Transfer.git
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/Example-Heat_Transfer

Set environment variable
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:[korvo lib path .../MPI_in_MPI/bebop-psm2/korvo-build/korvo/lib]

Change compilers in Makefile in Example-Heat_Transfer
$ vi Makefile
Line1: CC=mpicc #cc
Line2: FC=mpif90 #ftn

Compile Example-Heat_Transfer
$ make

$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/Example-Heat_Transfer/stage_write

Change compilers in Makefile in stage_write
$ vi Makefile
Line1: CC=mpicc #cc
Line2: FC=mpif90 #ftn

Compile stage_write
$ make

Execute
$ cd ~/project/bebop/MPI_in_MPI/bebop-psm2/Example-Heat_Transfer
$ mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
$ mpiexec -n 3 ./stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""

