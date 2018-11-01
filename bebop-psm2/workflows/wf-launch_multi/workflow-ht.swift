import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string dir, string infile) "turbine" "0.0"
[
"""
	file delete -force -- <<dir>>
	file mkdir <<dir>>
	cd <<dir>>
	file link -symbolic heat_transfer.xml <<infile>>
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
	cmds[0] = "../../../../../Example-Heat_Transfer/heat_transfer_adios2";
	cmds[1] = "../../../../../Example-Heat_Transfer/stage_write/stage_write";

	// Command line arguments
	string args[][];

	// mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
	args[0] = split("heat 2 1 40 50 6 5", " ");

	// mpiexec -n 3 stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""
	args[1] = split("heat.bp staged.bp FLEXPATH \"\" MPI \"\"", " ");

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir ];
	envs[1] = [ "swift_chdir="+dir ];
	// envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_heat_transfer_adios2.txt" ];
	// envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_stage_write.txt" ];

	// Color settings
	// colors = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11; 12, 13, 14";
	colors = "0, 1; 2, 3";

	string infile = "%s/heat_transfer.xml" % turbine_output;

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs, colors);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

