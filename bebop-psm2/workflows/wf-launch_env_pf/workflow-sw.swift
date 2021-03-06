import files;
import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string parDir, string srcDir, string dir) "turbine" "0.0"
[
"""
	file mkdir <<parDir>>
	file delete -force -- <<dir>>
	file copy -force -- <<srcDir>> <<dir>>
	cd <<dir>>
"""
];

(float exectime) launch_wrapper(string run_id, int params[], int count = 1)
{
	int time_limit = 2;
	if (count <= time_limit)
	{
		int sw_proc = params[0];	// StageWrite: total number of processes
		int sw_ppw = params[1];		// StageWrite: number of processes per worker
		int ht_step = params[2];	// HeatTransfer: the total number of steps to output

		string workflow_root = getenv("WORKFLOW_ROOT");
		string srcDir = "%s/experiment/wf-ht-bp%0.2i" % (workflow_root, ht_step);
		string turbine_output = getenv("TURBINE_OUTPUT");
		string parDir = "%s/run" % turbine_output;
		string dir = "%s/%s" % (parDir, run_id);

		int nwork1;
		if (sw_proc %% sw_ppw == 0) {
			nwork1 = sw_proc %/ sw_ppw;
		} else {
			nwork1 = sw_proc %/ sw_ppw + 1;
		}
		int timeout = 120 * float2int(2 ** count);

		string cmd1 = "../../../../../../Example-Heat_Transfer/stage_write/stage_write";

		// mpiexec -n 70 stage_write/stage_write heat.bp staged.bp MPI "" MPI ""
		string args1[] = split("heat.bp staged.bp MPI \"\" MPI \"\"", " ");

		string envs1[] = [ "swift_chdir="+dir, 
		       "swift_output="+dir/"output_stage_write.txt", 
		       "swift_exectime="+dir/"time_stage_write.txt",
		       "swift_timeout=%i" % timeout, 
		       "swift_numproc=%i" % sw_proc, 
		       "swift_ppw=%i" % sw_ppw ];

		printf("swift: launching with environment variables: %s", cmd1);
		setup_run(parDir, srcDir, dir) =>
			sleep(1) =>
			exit_code1 = @par=nwork1 launch_envs(cmd1, args1, envs1);

		if (exit_code1 == 124)
		{
			sleep(1) =>
				exectime = launch_wrapper(run_id, params, count + 1);
		}
		else
		{
			if (exit_code1 != 0)
			{
				exectime = -1.0;
				printf("swift: The launched application %s with parameters (%d, %d, %d) did not succeed with exit code: %d.", 
						cmd1, params[0], params[1], params[2], exit_code1);
			}
			else
			{
				exectime = get_exectime(run_id, params);
			}
		}
	}
	else
	{
		exectime = -1.0;
		printf("swift: The launched application with parameters (%d, %d, %d) did not succeed %d times.",
				params[0], params[1], params[2], time_limit);

	}
}

(float exectime) get_exectime(string run_id, int params[])
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_stage_write.txt" ];
	sleep(1) =>
		(time_output, time_exit_code) = system(cmd);

	if (time_exit_code != 0)
	{
		exectime = -1.0;
		printf("swift: Failed to get the execution time of the launched application of parameters (%d, %d, %d) with exit code: %d.\n%s",
				params[0], params[1], params[2], time_exit_code, time_output);
	}
	else
	{
		exectime = string2float(time_output);
		if (exectime >= 0.0)
		{
			printf("exectime(%i, %i, %i): %f", params[0], params[1], params[2], exectime);
			string output = "%0.4i\t%0.2i\t%0.2i\t%f" % (params[0], params[1], params[2], exectime);
			file out <dir/"time.txt"> = write(output);
		}
		else
		{
			printf("swift: The execution time (%f seconds) of the launched application with parameters (%d, %d, %d) is negative.",
					exectime, params[0], params[1], params[2]);
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

	// 0) StageWrite: total number of processes
	// 1) StageWrite: number of processes per worker
	// 2) HeatTransfer: the total number of steps to output
	int params_start[] = [4, 2, 32];
	int params_stop[] = [4, 2, 32];
	int params_step[] = [16, 16, 4];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1 ];

	float exectime[];
	int codes[];
/*
	for (int param1 = params_start[1], int flag10 = 0; param1 <= params_stop[1]; param1 = param1 + params_step[1], flag10 = sum(flag11))
	{
		int flag11[];
		if (param1 <= ppw)
		{
			for (int param0 = params_start[0], int flag00 = 0; param0 <= params_stop[0]; param0 = param0 + params_step[0], flag00 = sum(flag01))
			{
				int flag01[];
				if (param0 >= param1)
				{
					int nwork;
					if (param0 %% param1 == 0) {
						nwork = param0 %/ param1;
					} else {
						nwork = param0 %/ param1 + 1;
					}
					if (nwork <= workers)
					{
						int i = (param0 - params_start[0]) %/ params_step[0]
							* params_num[1]
							+ (param1 - params_start[1]) %/ params_step[1];
						exectime[i] = launch_wrapper("%0.4i_%0.2i_%0.2i"
								% (param0, param1, param2),
								[param0, param1, param2]);

						if (exectime[i] >= 0.0) {
							codes[i] = 0;
						} else {
							codes[i] = 1;
						}
						flag01[0] = codes[i];
						flag11[param0] = codes[i];
					}
				}
			}
		}
	}
*/
	foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
	{
		if (param1 <= ppw)
		{
			foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
			{
				if (param0 >= param1)
				{
					int nwork;
					if (param0 %% param1 == 0) {
						nwork = param0 %/ param1;
					} else {
						nwork = param0 %/ param1 + 1;
					}
					if (nwork <= workers)
					{
						foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
						{
							int i = (param0 - params_start[0]) %/ params_step[0]
								* params_num[1] * params_num[2]
								+ (param1 - params_start[1]) %/ params_step[1]
								* params_num[2]
								+ (param2 - params_start[2]) %/ params_step[2];
							exectime[i] = launch_wrapper("%0.4i_%0.2i_%0.2i"
									% (param0, param1, param2),
									[param0, param1, param2]);

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

	if (sum_integer(codes) == 0)
	{
		printf("swift: all the launched applications succeed.");
	}
}

