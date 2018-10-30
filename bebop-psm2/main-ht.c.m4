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
	int rank, size;
	char hostname[HOST_NAME_MAX];

	printf("Hello\n");
	fflush(stdout);

	gethostname(hostname, HOST_NAME_MAX);
	char machname[HOST_NAME_MAX];
	memset(machname, 0, HOST_NAME_MAX);
	if (argc > 1) {
		sprintf(machname, "%s", argv[1]);
	} else {
		sprintf(machname, "%s", hostname);
	}

	MPI_Init(0,0);

	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	printf("hostname:  %s\nrank/size: %i/%i\n", hostname, rank, size);
	fflush(stdout);

	size_t cmdlen;
	if (rank == 0) {
		char cmd1[] = "/usr/bin/time -v -o time_heat_transfer_adios2.txt mpiexec -n 12 -hosts ";
		char cmd2[] = " /blues/gpfs" PWD "/Example-Heat_Transfer/heat_transfer_adios2 heat 4 3 40 50 6 5 > output_heat_transfer_adios2.txt 2>&1 &";
		size_t cmdlen = strlen(cmd1) + strlen(machname) + strlen(cmd2) + 1;
		char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
		sprintf(mpicmd, "%s%s%s", cmd1, machname, cmd2);
		system(mpicmd);
	} else {
		char cmd1[] = "/usr/bin/time -v -o time_stage_write.txt mpiexec -n 3 -hosts ";
		char cmd2[] = " /blues/gpfs" PWD "/Example-Heat_Transfer/stage_write/stage_write heat.bp staged.bp FLEXPATH \"\" MPI \"\" > output_stage_write.txt 2>&1 &";
		size_t cmdlen = strlen(cmd1) + strlen(machname) + strlen(cmd2) + 1;
		char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
		sprintf(mpicmd, "%s%s%s", cmd1, machname, cmd2);
		system(mpicmd);
	}

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}

