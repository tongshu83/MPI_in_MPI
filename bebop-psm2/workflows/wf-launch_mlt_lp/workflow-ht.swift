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

(int exit_code) launch(string run_id, int params[]) 
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile = "%s/heat_transfer.xml" % turbine_output;
	int ppw = 5;

	// Worker counts
	int nworks[] = [2, 2];
        int ht_proc_x = params[0];
        int ht_proc_y = params[1];
        int sw_proc = params[2];

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
	envs[0] = [ "OMP_NUM_THREADS=4", 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_heat_transfer_adios2.txt", 
		"swift_exectime="+dir/"time_heat_transfer_adios2.txt", 
		"swift_numproc=%i" % (ht_proc_x * ht_proc_y), 
		"swift_ppw=%i" % ppw ];
	envs[1] = [ "OMP_NUM_THREADS=2", 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_stage_write.txt", 
		"swift_exectime="+dir/"time_stage_write.txt", 
		"swift_numproc=%i" % sw_proc, 
		"swift_ppw=%i" % ppw ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile) =>
		exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);
}

main()
{
	int codes[];

	int params_start[] = [2, 2, 5];
	int params_stop[] = [3, 3, 6];
	int params_step[] = [1, 1, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1 ];

	foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
	{
		foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
		{
			foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
			{
				int i = (param0 - params_start[0]) %/ params_step[0] * params_num[1] * params_num[2] 
					+ (param1 - params_start[1]) %/ params_step[1] * params_num[2] 
					+ (param2 - params_start[2]) %/ params_step[2];
				codes[i] = launch("%0.1i_%0.1i_%0.1i" % (param0, param1, param2), [param0, param1, param2]);

				if (codes[i] != 0)
				{
					printf("swift: The multi-launched application with parameters (%d, %d, %d) did not succeed with exit code: %d.",
							param0, param1, param2, codes[i]);
				}
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

