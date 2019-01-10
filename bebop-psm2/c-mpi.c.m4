changecom(`dnl')
#define __USE_POSIX

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>

define(`getenv', `esyscmd(printf -- "$`$1'")')
#define PWD "getenv(PWD)"

int main(int argc, char* argv[])
{
	int np = 2;
	if (argc > 1) {
		np = atoi(argv[1]);
	}

	// Start child processes.
	pid_t* pids = malloc(np * sizeof(pid_t)); 
	memset(pids, 0, np * sizeof(pid_t));
	int i;
	for (i = 0; i < np; ++i) {
		if ((pids[i] = fork()) < 0) {
			perror("fork");
			abort();
		} else if (pids[i] == 0) {
			pid_t pid = getpid();
			printf("Hello (Process %d).\n", pid);
			fflush(stdout);

			int proc = 36;
			if (argc > i * 2 + 2) {
				proc = atoi(argv[i * 2 + 2]);
			}

			char hostname[HOST_NAME_MAX];	// 64 chars
			gethostname(hostname, HOST_NAME_MAX);
			char machname[(HOST_NAME_MAX + 1) * 2];
			memset(machname, 0, (HOST_NAME_MAX + 1) * 2);
			if (argc > i * 2 + 3) {
				sprintf(machname, "%s", argv[i * 2 + 3]);
			} else {
				sprintf(machname, "%s", hostname);
			}
			printf("hostname (Process %d): %s\n", pid, hostname);
			fflush(stdout);

			char cmd1[] = "/usr/bin/time -v -o time_mpi_";
			char cmd2[] = ".txt mpiexec -n ";
			char cmd3[] = " -ppn 1 -hosts ";
			char cmd4[] = " -env OMP_NUM_THREADS=2 /blues/gpfs" PWD "/MPI/hello.x";
			size_t cmdlen = strlen(cmd1) + strlen(cmd2) + strlen(machname) + strlen(cmd3) + strlen(cmd4) + 21;
			char* mpicmd = (char*) malloc(cmdlen * sizeof(char));
			sprintf(mpicmd, "%s%d%s%d%s%s%s", cmd1, i, cmd2, proc, cmd3, machname, cmd4);
			printf("MPI command: %s\n", mpicmd);
			system(mpicmd);
			free(mpicmd);

			printf("Bye (Process %d).\n", pid);
			fflush(stdout);

			exit(0);
		}
	}

	// Wait for children to exit.
	int status;
	pid_t ch_pid;
	while (np > 0) {
		ch_pid = wait(&status);
		printf("Child with PID %ld exited with status 0x%x.\n", (long) ch_pid, status);
		--np;
	}
	free(pids);

	return 0;
}

