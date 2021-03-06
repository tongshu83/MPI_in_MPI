import io;
import launch;
import string;
import sys;

app printenv (string env) {
	"/usr/bin/printenv" env
}

main()
{
	// Process counts
	int proc = 2;

	// Command
	string cmd;
	cmd = "../../../../MPI/hello.x";

	// Command line arguments
	string args[] = [""];

	printf("swift: launching: %s", cmd);
	printenv("PPN");
	exit_code = @par=proc launch(cmd, args);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The launched application did not succeed.");
	}
}

