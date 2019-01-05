import io;
import launch;
import string;
import sys;

app printenv (string env) {
	"/usr/bin/printenv" env
}

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
	int proc = 2;

	// Command
	string cmd = "../../../../../scripts/script1.sh";

	// Command line arguments
	string args[] = [""];

	// Environment variables
	string envs[] = [ "OMP_NUM_THREADS=2", "swift_chdir="+dir ];

	printf("swift: launching with environment variables: %s", cmd);
	printenv("PPN");
	setup_run(dir) => 
		exit_code = @par=proc launch_envs(cmd, args, envs);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The launched application did not succeed.");
	}
}

