import files;
import io;
import launch;
import stats;
import string;
import sys;

// Problem Size of HeatTransfer
int ht_x = 4096;
int ht_y = 4096;
int ht_iter = 1000;

(void v) setup_run(string dir, string infile) "turbine" "0.0"
[
"""
	file delete -force -- <<dir>>
	file mkdir <<dir>>
	cd <<dir>>
	file link -symbolic heat_transfer.xml <<infile>>
"""
];

(float exectime) launch_wrapper(string run_id, int params[]) 
{
	int ht_proc_x = params[0];	// HeatTransfer: total number of processes in X dimension
	int ht_proc_y = params[1];	// HeatTransfer: total number of processes in Y dimension
	int ht_ppw = params[2];		// HeatTransfer: number of processes per worker
	int ht_step = params[3];	// HeatTransfer: the total number of steps to output
	int sw_proc = params[4];	// StageWrite: total number of processes
	int sw_ppw = params[5];		// StageWrite: number of processes per worker

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

	int ht_las_x = ht_x %/ ht_proc_x;
	int ht_las_y = ht_y %/ ht_proc_y;
	int ht_ips = ht_iter %/ ht_step;
	// mpiexec -n 12 ./heat_transfer_adios2 heat 4 3 40 50 6 5
	args[0] = split("heat %i %i %i %i %i %i" 
			% (ht_proc_x, ht_proc_y, ht_las_x, ht_las_y, ht_step, ht_ips), " ");

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
		printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d, %d) did not succeed with exit code: %d.", 
				ht_proc_x, ht_proc_y, ht_ppw, ht_step, sw_proc, sw_ppw, exit_code);
	}
	else
	{
		exectime = get_exectime(run_id, params);
	}
}

(float exectime) get_exectime(string run_id, int params[])
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_*.txt" ];
	sleep(1) =>
		(time_output, time_exit_code) = system(cmd);

	if (time_exit_code != 0)
	{
		exectime = -1.0;
		printf("swift: Failed to get the execution time of the multi-launched application of parameters (%d, %d, %d, %d, %d, %d) with exit code: %d.\n%s",
				params[0], params[1], params[2], params[3], params[4], params[5], time_exit_code, time_output);
	}
	else
	{
		exectime = string2float(time_output);
		if (exectime >= 0.0)
		{
			printf("exectime(%i, %i, %i, %i, %i, %i): %f",
					params[0], params[1], params[2], params[3], params[4], params[5], exectime);
			string output = "%0.2i\t%0.2i\t%0.2i\t%0.2i\t%0.2i\t%0.2i\t%f"
				% (params[0], params[1], params[2], params[3], params[4], params[5], exectime);
			file out <dir/"time.txt"> = write(output);
		}
		else
		{
			printf("swift: The execution time (%f seconds) of the multi-launched application with parameters (%d, %d, %d, %d, %d, %d) is negative.",
					exectime, params[0], params[1], params[2], params[3], params[4], params[5]);
		}
	}
}

main()
{
	int ppn = 36;   // bebop
	int wpn = string2int(getenv("PPN"));
	int ppw = ppn %/ wpn - 1;
	int workers;
	if (string2int(getenv("PROCS")) - 2 < 16) {
		workers = string2int(getenv("PROCS")) - 2;
	} else {
		workers = 16;
	}

	// 0) HeatTransfer: total number of processes in X dimension
	// 1) HeatTransfer: total number of processes in Y dimension
	// 2) HeatTransfer: number of processes per worker
	// 3) HeatTransfer: the total number of steps to output
	// 4) StageWrite: total number of processes
	// 5) StageWrite: number of processes per worker
	int params_start[] = [4, 4, 16, 10, 16, 16];
	int params_stop[] = [16, 16, 32, 10, 128, 32];
	int params_step[] = [4, 4, 16, 10, 16, 16];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1,
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1,
	    (params_stop[5] - params_start[5]) %/ params_step[5] + 1 ];

	float exectime[];
	int codes[];
	foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
	{
		if (param2 <= ppw)
		{
			foreach param5 in [params_start[5] : params_stop[5] : params_step[5]]
			{
				if (param5 <= ppw)
				{
					foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
					{
						foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
						{
							if (param0 * param1 >= param2)
							{
								foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
								{
									if (param4 >= param5)
									{
										int nwork;
										if (param0 * param1 %% param2 == 0 && param4 %% param5 == 0) {
											nwork = param0 * param1 %/ param2 + param4 %/ param5;
										} else {
											if (param0 * param1 %% param2 == 0 || param4 %% param5 == 0) {
												nwork = param0 * param1 %/ param2 + param4 %/ param5 + 1;
											} else {
												nwork = param0 * param1 %/ param2 + param4 %/ param5 + 2;
											}
										}
										if (nwork <= workers)
										{
											foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
											{
												int i = (param0 - params_start[0]) %/ params_step[0]
													* params_num[1] * params_num[2] * params_num[3] * params_num[4] * params_num[5]
													+ (param1 - params_start[1]) %/ params_step[1]
													* params_num[2] * params_num[3] * params_num[4] * params_num[5]
													+ (param2 - params_start[2]) %/ params_step[2]
													* params_num[3] * params_num[4] * params_num[5]
													+ (param3 - params_start[3]) %/ params_step[3]
													* params_num[4] * params_num[5]
													+ (param4 - params_start[4]) %/ params_step[4]
													* params_num[5]
													+ (param5 - params_start[5]) %/ params_step[5];
												exectime[i] = launch_wrapper("%0.2i_%0.2i_%0.2i_%0.2i_%0.2i_%0.2i"
														% (param0, param1, param2, param3, param4, param5),
														[param0, param1, param2, param3, param4, param5]);

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
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

