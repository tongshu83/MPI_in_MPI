
#define __USE_POSIX
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <mpi.h>

int main(int argc, char* argv[])
{
	printf("Hello.\n");
	fflush(stdout);

	MPI_Init(0,0);

	char hostname[HOST_NAME_MAX];
	gethostname(hostname, HOST_NAME_MAX);

	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	printf("PATH=");
	system("printenv PATH");
	printf("hostname:  %s\n", hostname);
	printf("rank/size: %i/%i\n", rank, size);

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}
