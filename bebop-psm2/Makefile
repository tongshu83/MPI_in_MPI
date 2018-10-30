all:
	m4 main-sh.c.m4 > main-sh.c
	# mpicc -E main-sh.c > main-sh.out
	m4 main-mpi.c.m4 > main-mpi.c
	# mpicc -E main-mpi.c > main-mpi.out
	m4 main-ht.c.m4 > main-ht.c
	# mpicc -E main-ht.c > main-ht.out
	m4 main-lammps.c.m4 > main-lammps.c
	# mpicc -E main-lammps.c > main-lammps.out
	mpicc -o main-sh.x main-sh.c
	mpicc -o main-mpi.x main-mpi.c
	mpicc -o main-ht.x main-ht.c
	mpicc -o main-lammps.x main-lammps.c
clean:
	rm -f main-sh.x main-mpi.x main-ht.x main-lammps.x main-sh.out main-mpi.out main-ht.out main-lammps.out
	rm -f time_*.txt output_*.txt log.lammps log.quench restart.glass_273K

