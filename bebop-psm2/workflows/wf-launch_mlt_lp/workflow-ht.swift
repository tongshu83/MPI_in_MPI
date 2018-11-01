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

(int exit_code) launch(string run_id, int ht_proc_x, int ht_proc_y, int sw_proc)
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Process counts
	int procs[] = [ht_proc_x * ht_proc_y, sw_proc];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../../Example-Heat_Transfer/heat_transfer_adios2";
	cmds[1] = "../../../../../../Example-Heat_Transfer/stage_write/stage_write";

	// Command line arguments
	string args[][];

	// mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
	int ht_x = 160;
	int ht_y = 150;
	args[0] = split("heat %i %i %i %i 6 5" % (ht_proc_x, ht_proc_y, ht_x %/ ht_proc_x, ht_y %/ ht_proc_y), " ");

	// mpiexec -n 3 stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""
	string method = "FLEXPATH";
	args[1] = split("heat.bp staged.bp %s \"\" MPI \"\"" % method , " ");

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir ];
	envs[1] = [ "swift_chdir="+dir ];
	// envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_heat_transfer_adios2.txt" ];
	// envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_stage_write.txt" ];

	string infile = "%s/heat_transfer.xml" % turbine_output;

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);
}

main()
{
	int codes[];

	int pars_low[] = [1, 1, 1];
	int pars_up[] = [5, 5, 7];
	foreach par0 in [pars_low[0] : pars_up[0]]
	{
		foreach par1 in [pars_low[1] : pars_up[1]]
		{
			foreach par2 in [pars_low[2] : pars_up[2]]
			{
				int i = (par0 - pars_low[0]) * (pars_up[1] - pars_low[1] + 1) * (pars_up[2] - pars_low[2] + 1) + (par1 - pars_low[1]) * (pars_up[2] - pars_low[2] + 1) + (par2 - pars_low[2]);
				codes[i] = launch("%000i_%000i_%000i" % (par0, par1, par2), par0, par1, par2);
				if (codes[i] != 0)
				{
					printf("swift: The multi-launched application with parameters (%d, %d, %d) did not succeed with exit code: %d.", par0, par1, par2, codes[i]);
				}
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

