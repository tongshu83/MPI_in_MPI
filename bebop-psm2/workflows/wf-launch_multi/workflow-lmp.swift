import assert;
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

main()
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string cmd[] = [ workflow_root/"lmp.sh", "100", "FLEXPATH" ];
	(pre_output, pre_exit_code) = system(cmd);

	if (pre_exit_code == 0)
	{
		string turbine_output = getenv("TURBINE_OUTPUT");
		string dir = "%s/run" % turbine_output;
		string infile1 = "%s/in.quench.short" % turbine_output;
		string infile2 = "%s/restart.liquid" % turbine_output;
		string infile3 = "%s/CuZr.fs" % turbine_output;

		// Process counts
		int procs[] = [2, 2];

		// Commands
		string cmds[];
		cmds[0] = "../../../../../Example-LAMMPS/swift-all/lmp_mpi";
		cmds[1] = "../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";

		// Command line arguments
		string args[][];

		// mpiexec -n 8 ./lmp_mpi -i in.quench.short
		args[0] = split("-i in.quench.short", " ");

		// mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH
		args[1] = split("dump.bp adios_atom_voro.bp FLEXPATH", " ");

		// Environment variables
		string envs[][];
		// envs[0] = [ "swift_chdir="+dir ];
		// envs[1] = [ "swift_chdir="+dir ];
		envs[0] = [ "OMP_NUM_THREADS=8", "swift_chdir="+dir, "swift_output="+dir/"output_lmp_mpi.txt", "swift_exectime="+dir/"time_lmp_mpi.txt" ];
		envs[1] = [ "OMP_NUM_THREADS=4", "swift_chdir="+dir, "swift_output="+dir/"output_voro_adios_omp_staging.txt", "swift_exectime="+dir/"time_voro_adios_omp_staging.txt" ];

		// Color settings
		// colors = "0, 1, 2, 3, 4, 5, 6, 7; 8, 9, 10, 11";
		colors = "0, 1; 2, 3";

		printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
		sleep(1) =>
			setup_run(dir, infile1, infile2, infile3) =>
			exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs, colors);
		printf("swift: received exit code: %d", exit_code);
		if (exit_code != 0)
		{
			printf("swift: The multi-launched applications did not succeed.");
		}
	}
}

