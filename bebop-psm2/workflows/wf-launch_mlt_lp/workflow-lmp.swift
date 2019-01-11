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
	file copy -force -- <<infile1>> in.quench.short
	file link -symbolic restart.liquid <<infile2>>
	file link -symbolic CuZr.fs <<infile3>>
"""
];

(int exit_code) launch(string run_id, int params[])
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile1 = "%s/in.quench.short" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;
	int ppw = 35;

	string cmd0[] = [ workflow_root/"lmp.sh", int2string(params[2]), "FLEXPATH", dir/"in.quench.short" ];
	setup_run(dir, infile1, infile2, infile3) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
		exit_code = exit_code0;
	}
	else
	{
		// Worker counts
		int nworks[] = [2, 2];

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
		envs[0] = [ "OMP_NUM_THREADS="+int2string(params[1]), 
			"swift_chdir="+dir, 
			"swift_output="+dir/"output_lmp_mpi.txt", 
			"swift_exectime="+dir/"time_lmp_mpi.txt", 
			"swift_numproc=%i" % params[0], 
			"swift_ppw=%i" % ppw ];
		envs[1] = [ "OMP_NUM_THREADS="+int2string(params[4]), 
			"swift_chdir="+dir, 
			"swift_output="+dir/"output_voro_adios_omp_staging.txt", 
			"swift_exectime="+dir/"time_voro_adios_omp_staging.txt", 
			"swift_numproc=%i" % params[3], 
			"swift_ppw=%i" % ppw ];

		printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
		sleep(1) =>
			exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);
	}
}

main()
{
	int codes[];

	int params_start[] = [35, 2, 100, 35, 2];
	int params_stop[] = [70, 3, 200, 70, 3];
	int params_step[] = [35, 1, 100, 35, 1];
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
						codes[i] = launch("%0.1i_%0.1i_%0.3i_%0.1i_%0.1i" % (param0, param1, param2, param3, param4), [param0, param1, param2, param3, param4]);

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
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

