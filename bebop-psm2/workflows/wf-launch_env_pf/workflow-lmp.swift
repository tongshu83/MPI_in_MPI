import files;
import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string dir, string infile1, string infile2, string infile3) "turbine" "0.0"
[
"""
	file delete -force -- <<dir>>
	file mkdir <<dir>>
	cd <<dir>>
	file copy -force -- <<infile1>> in.quench
	file link -symbolic restart.liquid <<infile2>>
	file link -symbolic CuZr.fs <<infile3>>
"""
];

(float exectime) launch_wrapper(string run_id, int params[])
{
	int lmp_proc = params[0];	// Lammps: total num of processes
	int lmp_ppw = params[1];	// Lammps: num of processes per worker
	int lmp_thrd = params[2];	// Lammps: num of threads per process
	int lmp_frqIO = params[3];	// Lammps: IO interval in steps

	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile1 = "%s/in.quench" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	string cmd0[] = [ workflow_root/"lmp.sh", int2string(lmp_frqIO), "POSIX", dir/"in.quench" ];
	setup_run(dir, infile1, infile2, infile3) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		exectime = -1.0;
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
	}
	else
	{
		int nwork1;
		if (lmp_proc %% lmp_ppw == 0) {
			nwork1 = lmp_proc %/ lmp_ppw;
		} else {
			nwork1 = lmp_proc %/ lmp_ppw + 1;
		}

		string cmd1 = "../../../../../../Example-LAMMPS/swift-all/lmp_mpi"; 

		string args1[] = split("-i in.quench", " ");	// mpiexec -n 8 ./lmp_mpi -i in.quench

		string envs1[] = [ "OMP_NUM_THREADS="+int2string(lmp_thrd), 
		       "swift_chdir="+dir, 
		       "swift_output="+dir/"output_lmp_mpi.txt", 
		       "swift_exectime="+dir/"time_lmp_mpi.txt",
		       "swift_numproc=%i" % lmp_proc,
		       "swift_ppw=%i" % lmp_ppw ];

		printf("swift: launching with environment variables: %s", cmd1);
		sleep(1) =>
			exit_code1 = @par=nwork1 launch_envs(cmd1, args1, envs1);

		if (exit_code1 != 0)
		{
			exectime = -1.0;
			printf("swift: The launched application %s with parameters (%d, %d, %d, %d) did not succeed with exit code: %d.", cmd1, params[0], params[1], params[2], params[3], exit_code1);
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

	string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_lmp_mpi.txt" ];
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
			printf("exectime(%i, %i, %i, %i): %f", params[0], params[1], params[2], params[3], exectime);
			string output = "%0.3i\t%0.2i\t%0.1i\t%0.4i\t%f\t" 
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
	int workers = string2int(getenv("PROCS")) - 2;

	// 0) Lammps: total num of processes
	// 1) Lammps: num of processes per worker
	// 2) Lammps: num of threads per process
	// 3) Lammps: IO interval in steps
	int params_start[] = [16, 8, 1, 100];
	int params_stop[] = [128, 32, 4, 1000];
	int params_step[] = [16, 8, 1, 900];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1 ];

	float exectime[];
	int codes[];
	foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
	{
		if (param1 <= ppw)
		{
			foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
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
						foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
						{
							int i = (param0 - params_start[0]) %/ params_step[0] 
								* params_num[1] * params_num[2] * params_num[3] 
								+ (param1 - params_start[1]) %/ params_step[1] 
								* params_num[2] * params_num[3] 
								+ (param2 - params_start[2]) %/ params_step[2] 
								* params_num[3] 
								+ (param3 - params_start[3]) %/ params_step[3];
							exectime[i] = launch_wrapper("%0.3i_%0.2i_%0.1i_%0.4i" % (param0, param1, param2, param3),
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
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the launched applications succeed.");
	}
}

