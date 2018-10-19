import assert;
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
	// Commands and process counts
	int procs[] = [2, 2];
	string cmds[];
	cmds[0] = "/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/hello.x";
	cmds[1] = "/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/MPI/hello.x";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	string turbine_output = getenv("TURBINE_OUTPUT");
	string outdir = "%s/run" % turbine_output;
        envs[0] = [ "swift_chdir="+outdir ];
        envs[1] = [ "swift_chdir="+outdir ];
	//envs[0] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_heat_transfer_adios2.txt" ];
	//envs[1] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_stage_write.txt" ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(outdir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

