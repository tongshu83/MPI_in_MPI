import assert;
import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string outdir, string infile1, string infile2, string infile3) "turbine" "0.0"
[
	"""
	file delete -force -- <<outdir>>
	file mkdir <<outdir>>
	cd <<outdir>>
	file link -symbolic in.quench.short <<infile1>>
	file link -symbolic restart.liquid <<infile2>>
	file link -symbolic CuZr.fs <<infile3>>
	"""
];

main()
{
	// Process counts
	int procs[] = [8, 4];

	// Commands
	string cmds[];
	cmds[0] = "../../../../Example-LAMMPS/swift-all/lmp_mpi";
	cmds[1] = "../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";

	// Command line arguments
	string args[][];

	// mpiexec -n 8 ./lmp_mpi -i in.quench.short
	args[0] = split("-i in.quench.short", " ");

	// mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp FLEXPATH
	args[1] = split("dump.bp adios_atom_voro.bp FLEXPATH", " ");

	// Environment variables
	string envs[][];
	string turbine_output = getenv("TURBINE_OUTPUT");
	string outdir = "%s/run" % turbine_output;
	envs[0] = [ "swift_chdir="+outdir ];
	envs[1] = [ "swift_chdir="+outdir ];
	// envs[0] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_lmp_mpi.txt" ];
	// envs[1] = [ "swift_chdir="+outdir, "swift_output="+outdir/"output_voro_adios_omp_staging.txt" ];

	// Color settings
	colors = "0, 1, 2, 3, 4, 5, 6, 7; 8, 9, 10, 11";

	string infile1 = "%s/in.quench.short" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(outdir, infile1, infile2, infile3) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs, colors);
	printf("swift: received exit code: %d", exit_code);
	if (exit_code != 0)
	{
		printf("swift: The multi-launched applications did not succeed.");
	}
}

