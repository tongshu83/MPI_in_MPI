import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string dir) "turbine" "0.0"
[
"""
	file mkdir <<dir>>
"""
];

main()
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run" % turbine_output;

	// Process counts
	int procs[] = [2, 2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../MPI/hello.x";
	cmds[1] = "../../../../../MPI/hello.x";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir ];
	envs[1] = [ "swift_chdir="+dir ];
	// envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_hello1.txt" ];
	// envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_hello2.txt" ];

	// Color settings
	colors = "0, 2; 1, 3";

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs, colors);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

