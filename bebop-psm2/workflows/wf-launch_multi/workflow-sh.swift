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
	// Process counts
	int procs[] = [2, 2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../scripts/script1.sh";
	cmds[1] = "../../../../scripts/script2.sh";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	string turbine_output = getenv("TURBINE_OUTPUT");
	string outdir = "%s/run" % turbine_output;
	// envs[0] = [ "swift_chdir="+outdir ];
	// envs[1] = [ "swift_chdir="+outdir ];
	envs[0] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_script1.txt" ];
	envs[1] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_script2.txt" ];

	// Color settings
	colors = "0, 2; 1, 3";

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(outdir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs, colors);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

