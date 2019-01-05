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
	file link -symbolic in.quench.short <<infile1>>
	file link -symbolic restart.liquid <<infile2>>
	file link -symbolic CuZr.fs <<infile3>>
"""
];

(int exit_code) launch(string run_id, int params[])
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string cmd0[] = [ workflow_root/"lmp.sh", int2string(params[4]), "FLEXPATH" ];
	(output0, exit_code0) = system(cmd0);

	if (exit_code0 == 0)
	{
		string turbine_output = getenv("TURBINE_OUTPUT");
		string dir = "%s/run/%s" % (turbine_output, run_id);
		string infile1 = "%s/in.quench.short" % turbine_output;
		string infile2 = "%s/restart.liquid" % turbine_output;
		string infile3 = "%s/CuZr.fs" % turbine_output;

		// Process counts
		int procs[] = [params[0], params[2]];

		// Commands
		string cmds[];
		cmds[0] = "../../../../../../Example-LAMMPS/swift-all/lmp_mpi";
		cmds[1] = "../../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";

		// Command line arguments
		string args[][];

		// mpiexec -n 8 ./lmp_mpi -i in.quench.short
		args[0] = split("-i in.quench.short", " ");

		// mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH
		args[1] = split("dump.bp adios_atom_voro.bp FLEXPATH", " ");

		// Environment variables
		string envs[][];
		envs[0] = [ "OMP_NUM_THREADS="+int2string(params[1]), "swift_chdir="+dir, "swift_output="+dir/"output_lmp_mpi.txt", "swift_exectime="+dir/"time_lmp_mpi.txt" ];
		envs[1] = [ "OMP_NUM_THREADS="+int2string(params[3]), "swift_chdir="+dir, "swift_output="+dir/"output_voro_adios_omp_staging.txt", "swift_exectime="+dir/"time_voro_adios_omp_staging.txt" ];

		printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
		sleep(1) =>
			setup_run(dir, infile1, infile2, infile3) =>
			exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);
	}
}

main()
{
	int codes[];

	int params_start[] = [2, 2, 2, 2, 100];	// [1, 1, 1, 1, 20];
	int params_stop[] = [3, 3, 3, 3, 200];	// [16, 16, 8, 8, 200];
	int params_step[] = [1, 1, 1, 1, 100];	// [1, 1, 1, 1, 20];
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
						codes[i] = launch("%0.2i_%0.2i_%0.2i_%0.2i_%0.3i" % (param0, param1, param2, param3, param4), [param0, param1, param2, param3, param4]);
						if (codes[i] != 0)
						{
							printf("swift: The multi-launched application with parameters (%d, %d, %d, %d, %d) did not succeed with exit code: %d.",
									param0, param1, param2, param3, param4, codes[i]);
						}
					}
				}
			}
		}
	}
}

