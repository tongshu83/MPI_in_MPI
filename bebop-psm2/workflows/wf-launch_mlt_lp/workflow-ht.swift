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
	file copy -force -- <<infile>> heat_transfer.xml
"""
];

// Problem Size of HeatTransfer
int ht_x = 160;
int ht_y = 150;
int ht_iter = 30;

(int exit_code) launch(string run_id, int params[])
{
	int ht_proc_x = params[0];	// HeatTransfer: total number of processes in X dimension
	int ht_proc_y = params[1];	// HeatTransfer: total number of processes in Y dimension
	int ht_ppw = params[2];		// HeatTransfer: number of processes per worker
	int ht_step = params[3];	// HeatTransfer: the total number of steps to output
	int ht_buff = params[4];	// HeatTransfer: the maximum size of I/O buffer
	int sw_proc = params[5];	// StageWrite: total number of processes
	int sw_ppw = params[6];		// StageWrite: number of processes per worker

	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile = "%s/heat_transfer.xml" % turbine_output;

	string cmd0[] = [ workflow_root/"ht.sh", "FLEXPATH", int2string(ht_buff), dir/"heat_transfer.xml" ];
	setup_run(dir, infile) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
		exit_code = exit_code0;
	}
	else
	{
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
		args[0] = split("heat %i %i %i %i %i %i" % (ht_proc_x, ht_proc_y, ht_las_x, ht_las_y, ht_step, ht_ips), " ");

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
		sleep(1) =>
			exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);
	}
}

main()
{
	int ppn = 36;   // bebop
	int wpn = string2int(getenv("PPN"));
	int ppw = ppn %/ wpn - 1;
	int workers = string2int(getenv("PROCS")) - 2;

	// 0) HeatTransfer: total number of processes in X dimension
	// 1) HeatTransfer: total number of processes in Y dimension
	// 2) HeatTransfer: number of processes per worker
	// 3) HeatTransfer: the total number of steps to output
	// 4) HeatTransfer: the maximum size of I/O buffer
	// 5) StageWrite: total number of processes
	// 6) StageWrite: number of processes per worker
	int params_start[] = [3, 5, 15, 6, 10, 17, 17];
	int params_stop[] = [6, 5, 30, 6, 10, 34, 34];
	int params_step[] = [3, 5, 15, 1, 10, 17, 17];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1,
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1,
	    (params_stop[5] - params_start[5]) %/ params_step[5] + 1,
	    (params_stop[6] - params_start[6]) %/ params_step[6] + 1 ];

	int codes[];
	foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
	{
		if (param2 <= ppw)
		{
			foreach param6 in [params_start[6] : params_stop[6] : params_step[6]]
			{
				if (param6 <= ppw)
				{
					foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
					{
						foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
						{
							foreach param5 in [params_start[5] : params_stop[5] : params_step[5]]
							{
								int nwork;
								if (param0 * param1 %% param2 == 0 && param5 %% param6 == 0) {
									nwork = param0 * param1 %/ param2 + param5 %/ param6;
								} else {
									if (param0 * param1 %% param2 == 0 || param5 %% param6 == 0) {
										nwork = param0 * param1 %/ param2 + param5 %/ param6 + 1;
									} else {
										nwork = param0 * param1 %/ param2 + param5 %/ param6 + 2;
									}
								}
								if (nwork <= workers)
								{
									foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
									{
										foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
										{
											int i = (param0 - params_start[0]) %/ params_step[0] 
												* params_num[1] * params_num[2] * params_num[3] * params_num[4] * params_num[5] * params_num[6] 
												+ (param1 - params_start[1]) %/ params_step[1] 
												* params_num[2] * params_num[3] * params_num[4] * params_num[5] * params_num[6]
												+ (param2 - params_start[2]) %/ params_step[2] 
												* params_num[3] * params_num[4] * params_num[5] * params_num[6]
												+ (param3 - params_start[3]) %/ params_step[3] 
												* params_num[4] * params_num[5] * params_num[6]
												+ (param4 - params_start[4]) %/ params_step[4] 
												* params_num[5] * params_num[6]
												+ (param5 - params_start[5]) %/ params_step[5]
												* params_num[6]
												+ (param6 - params_start[6]) %/ params_step[6];
											codes[i] = launch("%0.2i_%0.2i_%0.2i_%0.2i_%0.2i_%0.2i_%0.2i"
													% (param0, param1, param2, param3, param4, param5, param6),
													[param0, param1, param2, param3, param4, param5, param6]);

											if (codes[i] != 0)
											{
												printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d, %d, %d)
														did not succeed with exit code: %d.",
														param0, param1, param2, param3, param4, param5, param6, codes[i]);
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

