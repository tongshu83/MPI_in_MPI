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

	char hostname[HOST_NAME_MAX];   // 64 chars
	gethostname(hostname, HOST_NAME_MAX);
	printf("hostname : %s (rank/size: %i/%i)\n", hostname, rank, size);
	fflush(stdout);

	char machname[(HOST_NAME_MAX + 1) * 2];
	memset(machname, 0, (HOST_NAME_MAX + 1) * 2);

	if (rank == 0) {
		int x_proc = 4;
		if (argc > 1) {
			x_proc = atoi(argv[1]);
		}
		int y_proc = 3;
		if (argc > 2) {
			y_proc = atoi(argv[2]);
		}
		if (argc > 3) {
			sprintf(machname, "%s", argv[3]);
		} else {
			sprintf(machname, "%s", hostname);
		}

		char cmd1[] = "/usr/bin/time -v -o time_heat_transfer_adios2.txt mpiexec -n ";
		char cmd2[] = " -hosts ";
		char cmd3[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/Example-Heat_Transfer/heat_transfer_adios2 heat ";
		char cmd4[] = " 40 50 6 5 > output_heat_transfer_adios2.txt 2>&1 &";
		size_t cmdlen = strlen(cmd1) + strlen(cmd2) + strlen(machname) + strlen(cmd3) + strlen(cmd4) + 32;
		char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
		sprintf(mpicmd, "%s%d%s%s%s%d %d%s", cmd1, x_proc * y_proc, cmd2, machname, cmd3, x_proc, y_proc, cmd4);
		printf("MPI command: %s\n", mpicmd);
		system(mpicmd);
		free(mpicmd);
	}
	if (rank == 1) {
		int proc = 3;
		if (argc > 4) {
			proc = atoi(argv[4]);
		}
		if (argc > 5) {
			sprintf(machname, "%s", argv[5]);
		} else {
			sprintf(machname, "%s", hostname);
		}

		char cmd1[] = "/usr/bin/time -v -o time_stage_write.txt mpiexec -n ";
		char cmd2[] = " -hosts ";
		char cmd3[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/Example-Heat_Transfer/stage_write/stage_write heat.bp staged.bp FLEXPATH \"\" MPI \"\" > output_stage_write.txt 2>&1 &";
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

