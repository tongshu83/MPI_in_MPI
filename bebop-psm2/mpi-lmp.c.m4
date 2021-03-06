changecom(`dnl')
#define __USE_POSIX

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <mpi.h>

define(`getenv', `esyscmd(printf -- "$`$1'")')
#define PWD "getenv(PWD)"

int main(int argc, char* argv[])
{
	printf("Hello (main).\n");
	fflush(stdout);

	MPI_Init(NULL, NULL);

	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	int proc = 2;
	if (argc > rank * 2 + 1) {
		proc = atoi(argv[rank * 2 + 1]);
	}

	char hostname[HOST_NAME_MAX];   // 64 chars
	gethostname(hostname, HOST_NAME_MAX);
	char machname[(HOST_NAME_MAX + 1) * 2];
	memset(machname, 0, (HOST_NAME_MAX + 1) * 2);
	if (argc > rank * 2 + 2) {
		sprintf(machname, "%s", argv[rank * 2 + 2]);
	} else {
		sprintf(machname, "%s", hostname);
	}
	printf("hostname : %s (rank/size: %i/%i)\n", hostname, rank, size);
	fflush(stdout);

	if (rank == 0) {
		char cmd1[] = "/usr/bin/time -v -o time_lmp_mpi.txt mpiexec -n ";
		char cmd2[] = " -ppn 1 -hosts ";
		char cmd3[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/Example-LAMMPS/swift-all/lmp_mpi -i in.quench.short > output_lmp_mpi.txt 2>&1";
		size_t cmdlen = strlen(cmd1) + strlen(cmd2) + strlen(machname) + strlen(cmd3) + 11;
		char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
		sprintf(mpicmd, "%s%d%s%s%s", cmd1, proc, cmd2, machname, cmd3);
		printf("MPI command: %s\n", mpicmd);
		system(mpicmd);
		free(mpicmd);
	}
	if (rank == 1) {
		char cmd1[] = "/usr/bin/time -v -o time_voro_adios_omp_staging.txt mpiexec -n ";
		char cmd2[] = " -ppn 1 -hosts ";
		char cmd3[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/Example-LAMMPS/swift-all/voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH > output_voro_adios_omp_staging.txt 2>&1";
		size_t cmdlen = strlen(cmd1) + strlen(cmd2) + strlen(machname) + strlen(cmd3) + 11;
		char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
		sprintf(mpicmd, "%s%d%s%s%s", cmd1, proc, cmd2, machname, cmd3);
		printf("MPI command: %s\n", mpicmd);
		system(mpicmd);
		free(mpicmd);
	}

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}

