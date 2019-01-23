import files;
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

(float exectime) launch_wrapper(string run_id, int params[])
{
	int proc1 = params[0];                           
	int ppw1 = params[1];                               
	int thrd1 = params[2];
	int proc2 = params[3];
	int ppw2 = params[4]; 
	int thrd2 = params[5];

	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Worker counts
	int nworks[];
	if (proc1 %% ppw1 == 0) {
		nworks[0] = proc1 %/ ppw1;
	} else {       
		nworks[0] = proc1 %/ ppw1 + 1;
	}
	if (proc2 %% ppw2 == 0) {
		nworks[1] = proc2 %/ ppw2;
	} else {
		nworks[1] = proc2 %/ ppw2 + 1;
	}

	// Commands
	string cmds[];
	cmds[0] = "../../../../../../MPI/hello.x";
	cmds[1] = "../../../../../../MPI/hello.x";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	envs[0] = [ "OMP_NUM_THREADS="+int2string(thrd1), 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_hello1.txt", 
		"swift_exectime="+dir/"time_hello1.txt",
		"swift_numproc=%i" % proc1,
		"swift_ppw=%i" % ppw1 ];
	envs[1] = [ "OMP_NUM_THREADS="+int2string(thrd2), 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_hello2.txt", 
		"swift_exectime="+dir/"time_hello2.txt",
		"swift_numproc=%i" % proc2,
		"swift_ppw=%i" % ppw2 ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);

	if (exit_code != 0)
	{
		exectime = -1.0;
		printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d, %d) did not succeed with exit code: %d.", 
				params[0], params[1], params[2], params[3], params[4], params[5], exit_code);
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

	string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_hello*.txt" ];
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
		if (exectime >= 0.0) {
			printf("exectime(%i, %i, %i, %i, %i, %i): %f",
					params[0], params[1], params[2], params[3], params[4], params[5], exectime);
			string output = "%0.1i\t%0.1i\t%0.1i\t%0.1i\t%0.1i\t%0.1i\t%f\t"
				% (params[0], params[1], params[2], params[3], params[4], params[5], exectime);
			file out <dir/"time.txt"> = write(output);
		} else {
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
	int workers = string2int(getenv("PROCS")) - 2;

	int params_start[] = [2, 2, 2, 2, 2, 2];
	int params_stop[] = [3, 2, 3, 3, 2, 3];
	int params_step[] = [1, 1, 1, 1, 1, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1,
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1,
	    (params_stop[5] - params_start[5]) %/ params_step[5] + 1 ];

	float exectime[];
	int codes[];
	foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
	{
		printf("In the first level of loops");	// bug!!!
		if (param1 <= ppw)
		{
			foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
			{
				if (param4 <= ppw)
				{
					foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
					{
						foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
						{
							int nwork;
							if (param0 %% param1 == 0 && param3 %% param4 == 0) {
								nwork = param0 %/ param1 + param3 %/ param4;
							} else {
								if (param0 %% param1 == 0 || param3 %% param4 == 0) {
									nwork = param0 %/ param1 + param3 %/ param4 + 1;
								} else {
									nwork = param0 %/ param1 + param3 %/ param4 + 2;
								}
							}
							if (nwork <= workers)
							{
								foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
								{
									foreach param5 in [params_start[5] : params_stop[5] : params_step[5]]
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
										exectime[i] = launch_wrapper("%0.1i_%0.1i_%0.1i_%0.1i_%0.1i_%0.1i"
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
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

