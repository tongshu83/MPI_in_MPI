import io;
import files;
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

(float exectime) launch(string run_id, int proc1, int proc2)
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Process counts
	int procs[] = [proc1, proc2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../../scripts/script1.sh";
	cmds[1] = "../../../../../../scripts/script2.sh";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script1.txt", "swift_exectime="+dir/"time_script1.txt" ];
	envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script2.txt", "swift_exectime="+dir/"time_script2.txt" ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);

	if (exit_code == 0) {
		string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_script*.txt" ];
		sleep(1) =>
			(time_output, time_exit_code) = system(cmd);
		if (time_exit_code == 0) {
			exectime = string2float(time_output);
			if (exectime >= 0.0) {
				printf("exectime(%i, %i): %f", proc1, proc2, exectime);
				string output = "%0.1i\t%0.1i\t%f\t" % (proc1, proc2, exectime);
				file out <dir/"time.txt"> = write(output);
			} else {
				printf("swift: The execution time (%f seconds) of the multi-launched application with parameters (%d, %d) is negative.", exectime, proc1, proc2);
			}
		} else {
			exectime = -1.0;
			printf("swift: Failed to get the execution time of the multi-launched application of parameters (%d, %d) with exit code: %d.\n%s", proc1, proc2, time_exit_code, time_output);
		}
	} else {
		exectime = -1.0;
		printf("swift: The multi-launched application with parameters (%d, %d) did not succeed with exit code: %d.", proc1, proc2, exit_code);
	}
}

main()
{
	float exectime[];
	int codes[];

	int pars_low[] = [2, 2];
	int pars_up[] = [3, 3];
	foreach par0 in [pars_low[0] : pars_up[0]]
	{
		foreach par1 in [pars_low[1] : pars_up[1]]
		{
			int i = (par0 - pars_low[0]) * (pars_up[1] - pars_low[1] + 1) + (par1 - pars_low[1]);
			exectime[i] = launch("%0.1i_%0.1i" % (par0, par1), par0, par1);
			if (exectime[i] >= 0.0) {
				codes[i] = 0;
			} else {
				codes[i] = 1;
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

