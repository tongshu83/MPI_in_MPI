#!/bin/bash
#SBATCH -J mpi_in_mpi
#SBATCH -p bdwall
#SBATCH -N 1
#SBATCH --ntasks-per-node=36
#SBATCH -o /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/experiment/output.txt
#SBATCH -e /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/experiment/error.txt
#SBATCH -t 00:01:00
#SBATCH --workdir=/blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/experiment

export I_MPI_FABRICS=shm:tmi

# /usr/bin/time -v -o time_c-mpi.txt /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/c-mpi.x 2 38 bdw-0552 37 bdw-0553
# /usr/bin/time -v -o time_c-mpi.txt /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/c-mpi.x 2 38 bdw-0552,bdw-0553 34 bdw-0552,bdw-0553
# /usr/bin/time -v -o time_mpi-sh.txt mpiexec -n 72 -ppn 72 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/mpi-sh.x 
# /usr/bin/time -v -o time_mpi-mpi.txt mpiexec -n 2 -ppn 2 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/mpi-mpi.x 38 bdw-0552,bdw-0553 34 bdw-0552,bdw-0553
# /usr/bin/time -v -o time_mpi-ht.txt mpiexec -n 2 -ppn 2 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/mpi-ht.x 36 bdw-0098 36 bdw-0099
# /usr/bin/time -v -o time_mpi-ht.txt mpiexec -n 2 -ppn 2 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/mpi-ht.x 40 bdw-0098,bdw-0099 14 bdw-0098,bdw-0099
# /usr/bin/time -v -o time_mpi-lammps.txt mpiexec -n 2 -ppn 2 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/mpi-lammps.x 36 bdw-0098 36 bdw-0099

