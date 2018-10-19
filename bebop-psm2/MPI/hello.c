
#define __USE_POSIX
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <mpi.h>

int main(int argc, char* argv[])
{
	int rank, size;
	char hostname[HOST_NAME_MAX];

	printf("Hello\n");
	fflush(stdout);

	gethostname(hostname, HOST_NAME_MAX);

	MPI_Init(0,0);

	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	printf("hostname:  %s\n", hostname);
	printf("rank/size: %i/%i\n", rank, size);

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}
