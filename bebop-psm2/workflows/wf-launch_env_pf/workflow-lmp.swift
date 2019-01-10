import io;
import files;
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

(float exectime) launch(string run_id, int params[])
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile1 = "%s/in.quench" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	string cmd0[] = [ workflow_root/"lmp.sh", int2string(params[2]), "POSIX", dir/"in.quench"];
	setup_run(dir, infile1, infile2, infile3) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		exectime = -1.0;
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
	}
	else
	{
		int proc = params[0];
		string cmd = "../../../../../../Example-LAMMPS/swift-all/lmp_mpi"; 
		string args[] = split("-i in.quench", " ");	// mpiexec -n 8 ./lmp_mpi -i in.quench
		string envs[] = [ "OMP_NUM_THREADS="+int2string(params[1]), 
		       "swift_chdir="+dir, 
		       "swift_output="+dir/"output_lmp_mpi.txt", 
		       "swift_exectime="+dir/"time_lmp_mpi.txt" ];

		printf("swift: launching with environment variables: %s", cmd);
		sleep(1) =>
			exit_code = @par=proc launch_envs(cmd, args, envs);

		if (exit_code != 0)
		{
			exectime = -1.0;
			printf("swift: The launched application %s with parameters (%d, %d, %d) did not succeed with exit code: %d.", cmd, params[0], params[1], params[2], exit_code);
		}
		else
		{
			string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_lmp_mpi.txt" ];
			sleep(1) =>
				(time_output, time_exit_code) = system(cmd);

			if (time_exit_code != 0) 
			{
				exectime = -1.0;
				printf("swift: Failed to get the execution time of the launched application of parameters (%d, %d, %d) with exit code: %d.\n%s", params[0], params[1], params[2], time_exit_code, time_output);
			}
			else
			{
				exectime = string2float(time_output);
				if (exectime >= 0.0)
				{
					printf("exectime(%i, %i, %i): %f", params[0], params[1], params[2], exectime);
					string output = "%0.1i\t%0.1i\t%0.3i\t%f\t" % (params[0], params[1], params[2], exectime);
					file out <dir/"time.txt"> = write(output);
				}
				else
				{
					printf("swift: The execution time (%f seconds) of the launched application with parameters (%d, %d, %d) is negative.", exectime, params[0], params[1], params[2]);
				}
			}
		}
	}
}

main()
{
	float exectime[];
	int codes[];

	int params_start[] = [1, 1, 50];
	int params_stop[] = [2, 2, 100];
	int params_step[] = [1, 1, 50];
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
				exectime[i] = launch("%0.1i_%0.1i_%0.3i" % (param0, param1, param2), [param0, param1, param2]);

				if (exectime[i] >= 0.0) {
					codes[i] = 0;
				} else {
					codes[i] = 1;
				}
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the launched applications succeed.");
	}
}

