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
	file link -symbolic in.quench <<infile1>>
	file link -symbolic restart.liquid <<infile2>>
	file link -symbolic CuZr.fs <<infile3>>
"""
];

(float exectime) launch(string run_id, int params[])
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string cmd0[] = [ workflow_root/"lmp.sh", int2string(params[2]), "FLEXPATH" ];
	(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2], exit_code0);
		exit_code = exit_code0;
	}
	else
	{
		string turbine_output = getenv("TURBINE_OUTPUT");
		string dir = "%s/run/%s" % (turbine_output, run_id);
		string infile1 = "%s/in.quench" % turbine_output;
		string infile2 = "%s/restart.liquid" % turbine_output;
		string infile3 = "%s/CuZr.fs" % turbine_output;

		// Process counts
		int procs[] = [params[0], params[3]];

		// Commands
		string cmds[];
		cmds[0] = "../../../../../../Example-LAMMPS/swift-all/lmp_mpi";
		cmds[1] = "../../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";

		// Command line arguments
		string args[][];

		// mpiexec -n 8 ./lmp_mpi -i in.quench
		args[0] = split("-i in.quench", " ");

		// mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH
		args[1] = split("dump.bp adios_atom_voro.bp FLEXPATH", " ");

		// Environment variables
		string envs[][];
		envs[0] = [ "OMP_NUM_THREADS="+int2string(params[1]), "swift_chdir="+dir, "swift_output="+dir/"output_lmp_mpi.txt", "swift_exectime="+dir/"time_lmp_mpi.txt" ];
		envs[1] = [ "OMP_NUM_THREADS="+int2string(params[4]), "swift_chdir="+dir, "swift_output="+dir/"output_voro_adios_omp_staging.txt", "swift_exectime="+dir/"time_voro_adios_omp_staging.txt" ];

		printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
		sleep(1) =>
			setup_run(dir, infile1, infile2, infile3) =>
			exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);

		if (exit_code == 0) {
			string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_*.txt" ];
			sleep(1) =>
				(time_output, time_exit_code) = system(cmd);
			if (time_exit_code == 0) {
				exectime = string2float(time_output);
				if (exectime >= 0.0) {
					printf("exectime(%i, %i, %i, %i, %i): %f", params[0], params[1], params[2], params[3], params[4], exectime);
					string output = "%0.1i\t%0.1i\t%0.1i\t%0.1i\t%0.3i\t%f\t" % (params[0], params[1], params[2], params[3], params[4], exectime);
					file out <dir/"time.txt"> = write(output);
				} else {
					printf("swift: The execution time (%f seconds) of the multi-launched application with parameters (%d, %d, %d, %d, %d) is negative.", exectime, params[0], params[1], params[2], params[3], params[4]);
				}
			} else {
				exectime = -1.0;
				printf("swift: Failed to get the execution time of the multi-launched application of parameters (%d, %d, %d, %d, %d) with exit code: %d.\n%s", params[0], params[1], params[2], params[3], params[4], time_exit_code, time_output);
			}
		} else {
			exectime = -1.0;
			printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d) did not succeed with exit code: %d.", params[0], params[1], params[2], params[3], params[4], exit_code);
		}
	}
}

main()
{
	float exectime[];
	int codes[];

	int params_start[] = [1, 1, 50, 1, 1];
	int params_stop[] = [8, 4, 200, 8, 4];
	int params_step[] = [1, 1, 50, 1, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1,
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1 ];

	foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
	{
		foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
		{
			foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
			{
				foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
				{
					foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
					{
						int i = (param0 - params_start[0]) %/ params_step[0] * params_num[1] * params_num[2] * params_num[3] * params_num[4]
							+ (param1 - params_start[1]) %/ params_step[1] * params_num[2] * params_num[3] * params_num[4]
							+ (param2 - params_start[2]) %/ params_step[2] * params_num[3] * params_num[4]
							+ (param3 - params_start[3]) %/ params_step[3] * params_num[4]
							+ (param4 - params_start[4]) %/ params_step[4];
						exectime[i] = launch("%0.2i_%0.2i_%0.2i_%0.2i_%0.3i" % (param0, param1, param2, param3, param4), [param0, param1, param2, param3, param4]);
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
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

