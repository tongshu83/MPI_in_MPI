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

(int exit_code) launch(string run_id, int proc1, int proc2)
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
	envs[0] = [ "swift_chdir="+dir ];
	envs[1] = [ "swift_chdir="+dir ];
	// envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script1.txt" ];
	// envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script2.txt" ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);
}

main()
{
	int codes[];

	int pars_low[] = [2, 2];
	int pars_up[] = [3, 3];
	foreach par0 in [pars_low[0] : pars_up[0]]
	{
		foreach par1 in [pars_low[1] : pars_up[1]]
		{
			int i = (par0 - pars_low[0]) * (pars_up[1] - pars_low[1] + 1) + (par1 - pars_low[1]);
			codes[i] = launch("%000i_%000i" % (par0, par1), par0, par1);
			if (codes[i] != 0)
			{
				printf("swift: The multi-launched application %d did not succeed with exit code: %d.", i, codes[i]);
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

