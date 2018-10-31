import io;
import launch;
import string;
import sys;

main()
{
	// Process counts
	int proc = 2;

	// Command
	string cmd;
	cmd = "../../../../MPI/hello.x";

	// Command line arguments
	string args[] = [""];

	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run" % turbine_output;

	printf("swift: launching: %s", cmd);
	exit_code = @par=proc launch(cmd, args);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The launched application did not succeed.");
	}
}

