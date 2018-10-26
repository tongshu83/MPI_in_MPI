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

/usr/bin/time -v -o time_main-sh.txt mpiexec -n 2 /home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/main-sh.x 
/usr/bin/time -v -o time_main-mpi.txt mpiexec -n 2 /home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/main-mpi.x
/usr/bin/time -v -o time_main-ht.txt mpiexec -n 2 /home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/main-ht.x
/usr/bin/time -v -o time_main-lammps.txt mpiexec -n 2 /home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/main-lammps.x

