all:
	m4 mpi-sh.c.m4 > mpi-sh.c
	# mpicc -E mpi-sh.c > mpi-sh.out
	m4 mpi-mpi.c.m4 > mpi-mpi.c
	# mpicc -E mpi-mpi.c > mpi-mpi.out
	m4 mpi-ht.c.m4 > mpi-ht.c
	# mpicc -E mpi-ht.c > mpi-ht.out
	m4 mpi-lammps.c.m4 > mpi-lammps.c
	# mpicc -E mpi-lammps.c > mpi-lammps.out
	mpicc -o mpi-sh.x mpi-sh.c
	mpicc -o mpi-mpi.x mpi-mpi.c
	mpicc -o mpi-ht.x mpi-ht.c
	mpicc -o mpi-lammps.x mpi-lammps.c
	m4 c-mpi.c.m4 > c-mpi.c
	gcc -o c-mpi.x c-mpi.c
clean:
	rm -f mpi-sh.x mpi-mpi.x mpi-ht.x mpi-lammps.x mpi-sh.out mpi-mpi.out mpi-ht.out mpi-lammps.out
	rm -f c-mpi.c c-mpi.x
	rm -f time_*.txt output_*.txt log.lammps log.quench restart.glass_273K

