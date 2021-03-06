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
	printf("Hello.\n");
	fflush(stdout);

	MPI_Init(NULL, NULL);

	char hostname[HOST_NAME_MAX];
	gethostname(hostname, HOST_NAME_MAX);
	char machname[HOST_NAME_MAX];
	memset(machname, 0, HOST_NAME_MAX);
	if (argc > 1) {
		sprintf(machname, "%s", argv[1]);
	} else {
		sprintf(machname, "%s", hostname);
	}

	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	printf("hostname: %s\nrank/size: %i/%i\n", hostname, rank, size);
	fflush(stdout);

	char cmd1[] = "/usr/bin/time -v -o time_script1.txt mpiexec -n 2 -hosts ";
	char cmd2[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/scripts/script1.sh";
	size_t cmdlen = strlen(cmd1) + strlen(machname) + strlen(cmd2) + 1;
	char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
	sprintf(mpicmd, "%s%s%s", cmd1, hostname, cmd2);
	system(mpicmd);
	free(mpicmd);

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}

