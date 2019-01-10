import io;
import files;
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

(float exectime) launch(string run_id, int params[])
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string srcDir = "%s/experiment/wf-lmp-bp" % workflow_root;
	string turbine_output = getenv("TURBINE_OUTPUT");
	string parDir = "%s/run" % turbine_output;
	string dir = "%s/%s" % (parDir, run_id);

	int proc1 = params[0];
	string cmd1 = "../../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";
	string args1[] = split("dump.bp adios_atom_voro.bp BP", " ");     // mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp BP
	string envs1[] = [ "OMP_NUM_THREADS="+int2string(params[1]), 
	       "swift_chdir="+dir, 
	       "swift_output="+dir/"output_voro_adios_omp_staging.txt", 
	       "swift_exectime="+dir/"time_voro_adios_omp_staging.txt" ];

	printf("swift: launching with environment variables: %s", cmd1);
	setup_run(parDir, srcDir, dir) =>
		sleep(1) =>
		exit_code1 = @par=proc1 launch_envs(cmd1, args1, envs1);

	if (exit_code1 != 0)
	{
		exectime = -1.0;
		printf("swift: %s failed with exit code %d.", cmd1, exit_code1);
	}
	else
	{
		string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_voro_adios_omp_staging.txt" ];
		sleep(1) =>
			(time_output, time_exit_code) = system(cmd);

		if (time_exit_code != 0)
		{
			exectime = -1.0;
			printf("swift: Failed to get the execution time of the launched application of parameters (%d, %d) with exit code: %d.\n%s", params[0], params[1], time_exit_code, time_output);
		}
		else
		{
			exectime = string2float(time_output);
			if (exectime >= 0.0)
			{
				printf("exectime(%i, %i): %f", params[0], params[1], exectime);
				string output = "%0.1i\t%0.1i\t%f\t" % (params[0], params[1], exectime);
				file out <dir/"time.txt"> = write(output);
			}
			else
			{
				printf("swift: The execution time (%f seconds) of the launched application with parameters (%d, %d) is negative.", exectime, params[0], params[1]);
			}
		}
	}
}

main()
{
	float exectime[];
	int codes[];

	int params_start[] = [2, 1];
	int params_stop[] = [8, 4];
	int params_step[] = [1, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1 ];

	foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
	{
		foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
		{
			int i = (param0 - params_start[0]) %/ params_step[0] * params_num[1] + (param1 - params_start[1]) %/ params_step[1];
			exectime[i] = launch("%0.1i_%0.1i" % (param0, param1), [param0, param1]);

			if (exectime[i] >= 0.0) {
				codes[i] = 0;
			} else {
				codes[i] = 1;
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the launched applications succeed.");
	}
}

