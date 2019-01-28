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

(void v) setup_input(string dir, string infile) "turbine" "0.0"
[
"""
	file delete -force -- <<dir>>
	file mkdir <<dir>>
	cd <<dir>>
	file copy -force -- <<infile>> heat_transfer.xml
"""
];

(float exectime) launch_wrapper(string run_id, int params[])
{
	int ht_proc_x = params[0];	// HeatTransfer: total number of processes in X dimension
	int ht_proc_y = params[1];	// HeatTransfer: total number of processes in Y dimension
	int ht_ppw = params[2];		// HeatTransfer: number of processes per worker
	int ht_step = params[3];	// HeatTransfer: the total number of steps to output

	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT"); 
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile = "%s/heat_transfer.xml" % turbine_output;

	string cmd0[] = [ workflow_root/"ht.sh", "MPI", dir/"heat_transfer.xml" ];
	setup_input(dir, infile) =>     
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		exectime = -1.0;
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2], exit_code0);
	}
	else
	{
		int nwork1;
		int ht_proc = ht_proc_x * ht_proc_y;
		if (ht_proc %% ht_ppw == 0) {
			nwork1 = ht_proc %/ ht_ppw;
		} else {
			nwork1 = ht_proc %/ ht_ppw + 1;
		}

		string cmd1 = "../../../../../../Example-Heat_Transfer/heat_transfer_adios2";

		int ht_las_x = ht_x %/ ht_proc_x;
		int ht_las_y = ht_y %/ ht_proc_y;
		int ht_ips = ht_iter %/ ht_step;
		// mpiexec -n 70 ./heat_transfer_adios2 heat 10 7 40 50 6 5
		string args1[] = split("heat %i %i %i %i %i %i" 
				% (ht_proc_x, ht_proc_y, ht_las_x, ht_las_y, ht_step, ht_ips), " ");

		string envs1[] = [ "swift_chdir="+dir, 
		       "swift_output="+dir/"output_heat_transfer_adios2.txt", 
		       "swift_exectime="+dir/"time_heat_transfer_adios2.txt",
		       "swift_numproc=%i" % ht_proc,
		       "swift_ppw=%i" % ht_ppw ];

		printf("swift: launching with environment variables: %s", cmd1);
		sleep(1) =>
			exit_code1 = @par=nwork1 launch_envs(cmd1, args1, envs1);

		if (exit_code1 != 0)
		{
			exectime = -1.0;
			printf("swift: The launched application %s with parameters (%d, %d, %d, %d) did not succeed with exit code: %d.", 
					cmd1, params[0], params[1], params[2], params[3], exit_code1);
		}
		else
		{
			exectime = get_exectime(run_id, params);
		}
	}
}

(float exectime) get_exectime(string run_id, int params[])
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_heat_transfer_adios2.txt" ];
	sleep(1) =>
		(time_output, time_exit_code) = system(cmd);

	if (time_exit_code != 0)
	{
		exectime = -1.0;
		printf("swift: Failed to get the execution time of the launched application of parameters (%d, %d, %d, %d) with exit code: %d.\n%s",
				params[0], params[1], params[2], params[3], time_exit_code, time_output);
	}
	else
	{
		exectime = string2float(time_output);
		if (exectime >= 0.0)
		{
			printf("exectime(%i, %i, %i, %i): %f", 
					params[0], params[1], params[2], params[3], exectime);
			string output = "%0.2i\t%0.2i\t%0.2i\t%0.4i\t%f" 
				% (params[0], params[1], params[2], params[3], exectime);
			file out <dir/"time.txt"> = write(output);
		}
		else
		{
			printf("swift: The execution time (%f seconds) of the launched application with parameters (%d, %d, %d, %d) is negative.",
					exectime, params[0], params[1], params[2], params[3]);
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
	int params_start[] = [4, 4, 8, 10];
	int params_stop[] = [16, 16, 32, 100];
	int params_step[] = [4, 4, 8, 90];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1 ];

	float exectime[];
	int codes[];
	foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
	{
		if (param2 <= ppw)
		{
			foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
			{
				foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
				{
					if (param0 * param1 >= param2)
					{
						int nwork;
						if (param0 * param1 %% param2 == 0) {
							nwork = param0 * param1 %/ param2;
						} else {
							nwork = param0 * param1 %/ param2 + 1;
						}
						if (nwork <= workers)
						{
							foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
							{
								int i = (param0 - params_start[0]) %/ params_step[0]
									* params_num[1] * params_num[2] * params_num[3]
									+ (param1 - params_start[1]) %/ params_step[1]
									* params_num[2] * params_num[3]
									+ (param2 - params_start[2]) %/ params_step[2]
									* params_num[3]
									+ (param3 - params_start[3]) %/ params_step[3];
								exectime[i] = launch_wrapper("%0.2i_%0.2i_%0.2i_%0.4i"
										% (param0, param1, param2, param3),
										[param0, param1, param2, param3]);

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
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the launched applications succeed.");
	}
}

