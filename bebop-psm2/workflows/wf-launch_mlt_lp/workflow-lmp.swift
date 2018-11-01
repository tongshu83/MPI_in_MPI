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

(int exit_code) launch(string run_id, int proc1, int proc2)
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Process counts
	int procs[] = [proc1, proc2];

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
	envs[0] = [ "swift_chdir="+dir ];
	envs[1] = [ "swift_chdir="+dir ];
	// envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_lmp_mpi.txt" ];
	// envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_voro_adios_omp_staging.txt" ];

	string infile1 = "%s/in.quench.short" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir, infile1, infile2, infile3) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);
}

main()
{
	int codes[];
	int pars_low[] = [1, 1];
	int pars_up[] = [16, 16];
	foreach par0 in [pars_low[0] : pars_up[0]]
	{
		foreach par1 in [pars_low[1] : pars_up[1]]
		{
			int i = (par0 - pars_low[0]) * (pars_up[1] - pars_low[1] + 1) + (par1 - pars_low[1]);
			codes[i] = launch("%000i_%000i" % (par0, par1), par0, par1);
			if (codes[i] != 0)
			{
				printf("swift: The multi-launched application with parameters (%d, %d) did not succeed with exit code: %d.", par0, par1, codes[i]);
			}
		}
	}
	if (sum_integer(codes) == 0)
	{
		printf("swift: all the multi-launched applications succeed.");
	}
}

