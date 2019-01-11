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
	string infile = "%s/heat_transfer.xml" % turbine_output;

	// Worker counts
	int nworks[] = [2, 2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../Example-Heat_Transfer/heat_transfer_adios2";
	cmds[1] = "../../../../../Example-Heat_Transfer/stage_write/stage_write";

	// Command line arguments
	string args[][];

	// mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
	args[0] = split("heat 10 7 40 50 6 5", " ");

	// mpiexec -n 3 stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""
	args[1] = split("heat.bp staged.bp FLEXPATH \"\" MPI \"\"", " ");

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir, 
		"swift_output="+dir/"output_heat_transfer_adios2.txt", 
		"swift_exectime="+dir/"time_heat_transfer_adios2.txt",
		"swift_numproc=70",
		"swift_ppw=35" ];
	envs[1] = [ "swift_chdir="+dir, 
		"swift_output="+dir/"output_stage_write.txt", 
		"swift_exectime="+dir/"time_stage_write.txt",
		"swift_numproc=70",
		"swift_ppw=35" ];

	// Color settings
	colors = "0, 1; 2, 3";

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile) =>
		exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs, colors);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

