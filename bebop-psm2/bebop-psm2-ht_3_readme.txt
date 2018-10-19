
Download Example-Heat_Transfer
$ git clone https://github.com/CODARcode/Example-Heat_Transfer.git
$ cd Example-Heat_Transfer

Set environment variable
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:[korvo lib path .../MPI_in_MPI/bebop-psm2/korvo-build/korvo/lib]

Change compilers in Makefile in Example-Heat_Transfer
$ vi Makefile
Line1: CC=mpicc #cc
Line2: FC=mpif90 #ftn

Compile Example-Heat_Transfer
$ make

$ cd Example-Heat_Transfer/stage_write

Change compilers in Makefile in stage_write
$ vi Makefile
Line1: CC=mpicc #cc
Line2: FC=mpif90 #ftn

Compile stage_write
$ make

