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

	char cmd1[] = "/usr/bin/time -v -o time_mpi_";
	char cmd2[] = ".txt mpiexec -n ";
	char cmd3[] = " -ppn 1 -hosts ";
	char cmd4[] = " /blues/gpfs" PWD "/MPI/hello.x";
	size_t cmdlen = strlen(cmd1) + strlen(cmd2) + strlen(cmd3) + strlen(cmd4) + strlen(machname) + 21;
	char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
	sprintf(mpicmd, "%s%d%s%d%s%s%s", cmd1, rank, cmd2, proc, cmd3, machname, cmd4);
	printf("MPI command: %s\n", mpicmd);
	system(mpicmd);
	free(mpicmd);

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye (main).\n");
	fflush(stdout);
	return 0;
}

