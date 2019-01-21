import files;
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

(float exectime) launch(string run_id, int params[]) 
{
	int ht_proc_x = params[0];
	int ht_proc_y = params[1];
	int ht_ppw = params[2];
	int sw_proc = params[3];
	int sw_ppw = params[4];

	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile = "%s/heat_transfer.xml" % turbine_output;

	// Worker counts
	int nworks[];
	ht_proc = ht_proc_x * ht_proc_y;
	if (ht_proc %% ht_ppw == 0) {
		nworks[0] = ht_proc %/ ht_ppw;
	} else {
		nworks[0] = ht_proc %/ ht_ppw + 1;
	}
	if (sw_proc %% sw_ppw == 0) {
		nworks[1] = sw_proc %/ sw_ppw;
	} else {
		nworks[1] = sw_proc %/ sw_ppw + 1;
	}

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
	envs[0] = [ "swift_chdir="+dir, 
		"swift_output="+dir/"output_heat_transfer_adios2.txt", 
		"swift_exectime="+dir/"time_heat_transfer_adios2.txt", 
		"swift_numproc=%i" % ht_proc, 
		"swift_ppw=%i" % ht_ppw ];
	envs[1] = [ "swift_chdir="+dir, 
		"swift_output="+dir/"output_stage_write.txt", 
		"swift_exectime="+dir/"time_stage_write.txt", 
		"swift_numproc=%i" % sw_proc, 
		"swift_ppw=%i" % sw_ppw ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile) =>
		exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);

	if (exit_code != 0)
	{
		exectime = -1.0;
		printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d) did not succeed with exit code: %d.", ht_proc_x, ht_proc_y, ht_ppw, sw_proc, sw_ppw, exit_code);
	}
	else
	{
		string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_*.txt" ];
		sleep(1) =>
			(time_output, time_exit_code) = system(cmd);

		if (time_exit_code != 0)
		{
			exectime = -1.0;
			printf("swift: Failed to get the execution time of the multi-launched application of parameters (%d, %d, %d, %d, %d) with exit code: %d.\n%s", ht_proc_x, ht_proc_y, ht_ppw, sw_proc, sw_ppw, time_exit_code, time_output);
		}
		else
		{
			exectime = string2float(time_output);
			if (exectime >= 0.0)
			{
				printf("exectime(%i, %i, %i, %i, %i): %f", ht_proc_x, ht_proc_y, ht_ppw, sw_proc, sw_ppw, exectime);
				string output = "%0.2i\t%0.2i\t%0.2i\t%0.2i\t%0.2i\t%f\t" % (ht_proc_x, ht_proc_y, ht_ppw, sw_proc, sw_ppw, exectime);
				file out <dir/"time.txt"> = write(output);
			}
			else
			{
				printf("swift: The execution time (%f seconds) of the multi-launched application with parameters (%d, %d, %d, %d, %d) is negative.", exectime, ht_proc_x, ht_proc_y, ht_ppw, sw_proc, sw_ppw);
			}
		}
	}
}

main()
{
	int ppn = 36;   // bebop
	int wpn = string2int(getenv("PPN"));
	int ppw = ppn %/ wpn - 1;
	int workers = string2int(getenv("PROCS")) - 2;

	// 0) HeatTransfer: num of processes in X
	// 1) HeatTransfer: num of processes in Y
	// 2) HeatTransfer: num of processes per worker
	// 3) StageWrite: total num of processes
	// 4) StageWrite: num of processes per worker
	int params_start[] = [6, 5, 15, 34, 17];
	int params_stop[] = [6, 5, 30, 34, 34];
	int params_step[] = [6, 5, 15, 34, 17];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1, 
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1, 
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1, 
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1, 
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1 ];

	float exectime[];
	int codes[];
	foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
	{
		if (param2 <= ppw)
		{
			foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
			{
				if (param4 <= ppw)
				{
					foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
					{
						foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
						{
							foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
							{
								int nwork;
								if (param0 * param1 %% param2 == 0 && param3 %% param4 == 0) {
									nwork = param0 * param1 %/ param2 + param3 %/ param4;
								} else {
									if (param0 * param1 %% param2 == 0 || param3 %% param4 == 0) {
										nwork = param0 * param1 %/ param2 + param3 %/ param4 + 1;
									} else {
										nwork = param0 * param1 %/ param2 + param3 %/ param4 + 2;
									}
								}
								if (nwork <= workers)
								{
									int i = (param0 - params_start[0]) %/ params_step[0]
										* params_num[1] * params_num[2] * params_num[3] * params_num[4]
										+ (param1 - params_start[1]) %/ params_step[1]
										* params_num[2] * params_num[3] * params_num[4]
										+ (param2 - params_start[2]) %/ params_step[2]
										* params_num[3] * params_num[4]
										+ (param3 - params_start[3]) %/ params_step[3]
										* params_num[4]
										+ (param4 - params_start[4]) %/ params_step[4];
									exectime[i] = launch("%0.2i_%0.2i_%0.2i_%0.2i_%0.2i"
											% (param0, param1, param2, param3, param4),
											[param0, param1, param2, param3, param4]);

									if (exectime[i] >= 0.0) {
										codes[i] = 0;
									} else {
										codes[i] = 1;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

