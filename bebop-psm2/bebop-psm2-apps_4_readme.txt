
1. A single MPI

Compile a MPI code in a computing node
$ cd MPI
$ make

Run MPI in a computing node
$ mpiexec -n 2 MPI/hello.x

or

Submit a MPI job from the login node (Note: Edit the path in sbatch-bebop.sh)
$ sbatch MPI/sbatch-bebop-mpi.sh


2. Heat_Transfer

Run Heat_Transfer in a computing node
$ mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
$ mpiexec -n 3 stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""

or
Submit Heat_Transfer from the login node (Note: Edit the path in sbatch-bebop-ht.sh)
Create experiment in Example-Heat_Transfer
$ mkdir Example-Heat_Transfer/experiment
Copy heat_transfer.xml into work directory
$ cp Example-Heat_Transfer/heat_transfer.xml Example-Heat_Transfer/experiment/heat_transfer.xml
Submit the Heat_Transfer job
$ sbatch Example-Heat_Transfer/sbatch-bebop-ht.sh


3. Script, MPI, and Heat_Transfer inside MPI
Compile main-sh.c, main-mpi.c, and main-ht.c in a computing node (Note: Edit the path in main-sh.c, main-mpi.c, and main-ht.c)
$ make

Run in a computing node
$ mpiexec -n 2 main-sh.x
$ mpiexec -n 2 main-mpi.x
$ mpiexec -n 2 main-ht.x

or

Submit from the login node (Note: Edit the path in sbatch-bebop.sh)
$ sbatch sbatch-bebop.sh

