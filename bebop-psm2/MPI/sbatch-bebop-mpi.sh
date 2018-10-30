#!/bin/bash
#SBATCH -J mpi
#SBATCH -p bdwall
#SBATCH -N 2
#SBATCH --ntasks-per-node=36
#SBATCH -o /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/experiment/output.txt
#SBATCH -e /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/experiment/error.txt
#SBATCH -t 00:01:00
#SBATCH --workdir=/blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/experiment/

export I_MPI_FABRICS=shm:tmi

/usr/bin/time -v -o time_hello.txt mpiexec -n 2 -ppn 1 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/hello.x
# mpiexec -n 2 -ppn 1 -hosts bdw-0551,bdw-0552 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/hello.x
# srun -n 2 -N 2 -w bdw-0551,bdw-0552 /blues/gpfs/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/hello.x

