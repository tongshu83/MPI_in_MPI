
#define __USE_POSIX
#include <limits.h>
#include <stdio.h>
#include <unistd.h>
#include <mpi.h>
#include <omp.h>

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

	printf("hostname:  %s\n", hostname);
	printf("rank/size: %i/%i\n", rank, size);

	printf("OMP_NUM_THREADS=");
	system("printenv OMP_NUM_THREADS");
	if (argc > 1) {
		omp_set_num_threads(atoi(argv[1]));
	}

	#pragma omp parallel
	{
		int id = omp_get_thread_num();
		int nthrds = omp_get_num_threads();
		printf("%d/%d: hello world!\n", id, nthrds);
	}

	MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	printf("Bye.\n");
	fflush(stdout);
	return 0;
}

