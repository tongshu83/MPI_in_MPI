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

(float value) launch(string run_id, string pars)
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	int proc1 = string2int(json_get(pars, "par0"));
	int proc2 = string2int(json_get(pars, "par1"));

	// Process counts
	int procs[] = [proc1, proc2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../scripts/script1.sh";
	cmds[1] = "../../../../../scripts/script2.sh";

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

main()
{
	string par_arr[];
	float vals[];

	int pars_low[] = [2, 2];
	int pars_up[] = [3, 3];
	foreach par0 in [pars_low[0] : pars_up[0]]
	{
		foreach par1 in [pars_low[1] : pars_up[1]]
		{
			int i = (par0 - pars_low[0]) * (pars_up[1] - pars_low[1]) + (par1 - pars_low[1]);
			par_arr[i] = "{\"par0\":%i,\"par1\":%i}" % (par0, par1);
			vals[i] = obj(par_arr[i], "%000i_%000i" % (par0, par1));
		}
	}

}

