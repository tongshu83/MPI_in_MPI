import io;
import launch;
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
	// Process counts
	int proc = 2;

	// Command
	string cmd;
	cmd = "../../../../scripts/script.sh";

	// Command line arguments
	string args[] = [""];

	// Environment variables
	string turbine_output = getenv("TURBINE_OUTPUT");
	string outdir = "%s/run" % turbine_output;
	string envs[] = [ "swift_chdir="+outdir ];

	printf("swift: launching with environment variables: %s", cmd);
	setup_run(outdir) =>
		exit_code = @par=proc launch_envs(cmd, args, envs);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The launched application did not succeed.");
	}
}

