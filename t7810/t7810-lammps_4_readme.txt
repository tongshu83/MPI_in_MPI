
$ cd ~/project/MPI_in_MPI/t7810
Download
$ git clone https://github.com/CODARcode/Example-LAMMPS.git
$ cd Example-LAMMPS


Compile LAMMPS
$ cd lammps/src
$ #rm -f liblammps.so
$ make yes-kspace yes-manybody yes-molecule yes-user-adios_staging
$ make mpi -j8
$ make mpi -j8 mode=shlib


Compile voro++-0.4.6
$ cd ../../voro++-0.4.6/src
$ make -j8 CXX=mpicxx CFLAGS=-fPIC


Compile adios_integration
$ cd ../../adios_integration
$ make -j8


Compile swift-liblammps
$ cd ../swift-liblammps
$ vi build.sh
Line 3: source $(turbine -C)
Line 7: MPICC=$( which mpicc )

$ ./build.sh


Compile swift-voro_adios
$ cd ../swift-voro_adios
$ vi build.sh
Line 3: source $(turbine -C)
Line 7: MPICXX=$( which mpicxx )

$ ./build.sh


Compile swift-all
$ cd ../swift-all

$ ./build-16k.sh


Execute
$ cd ../swift-all
$ export PATH=/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/lammps/src:/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/adios_integration:$PATH
$ mpirun -n 8 ./lmp_mpi -i in.quench.short
$ mpirun -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH

OR

$ vi run.sh
Line 15: #module load mvapich2-gnu-psm/1.9
Line 34: #export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu
Line 35: PATH=/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/adios_integration:$PATH
Line 36: PATH=/home/tshu/project/MPI_in_MPI/t7810/Example-LAMMPS/lammps/src:$PATH

$ ./run.sh

