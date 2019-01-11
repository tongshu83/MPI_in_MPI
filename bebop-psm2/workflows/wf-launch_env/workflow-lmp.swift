import io;
import launch;
import stats;
import string;
import sys;

app printenv (string env) {
	"/usr/bin/printenv" env
}

(void v) setup_input(string dir, string infile1, string infile2, string infile3) "turbine" "0.0"
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

(void v) setup_run(string dir) "turbine" "0.0"
[
"""
	cd <<dir>>
"""
];

main()
{
	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run" % turbine_output;
	string infile1 = "%s/in.quench.short" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	string cmd0[] = [ workflow_root/"lmp.sh", "100", "POSIX", dir/"in.quench.short"];
	setup_input(dir, infile1, infile2, infile3) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
	}
	else
	{
		int nwork1 = 2;
		string cmd1 = "../../../../../Example-LAMMPS/swift-all/lmp_mpi"; 
		string args1[] = split("-i in.quench.short", " ");	// mpiexec -n 8 ./lmp_mpi -i in.quench.short
		string envs1[] = [ "OMP_NUM_THREADS=4", 
		       "swift_chdir="+dir, 
		       "swift_output="+dir/"output_lmp_mpi.txt", 
		       "swift_exectime="+dir/"time_lmp_mpi.txt", 
		       "swift_numproc=3", 
		       "swift_ppw=2" ];

		printf("swift: launching with environment variables: %s", cmd1);
		sleep(1) =>
			setup_run(dir) =>
			exit_code1 = @par=nwork1 launch_envs(cmd1, args1, envs1);

		if (exit_code1 != 0)
		{
			printf("swift: %s failed with exit code %d.", cmd1, exit_code1);
		}
		else
		{
			string cmd2[] = split("bpmeta --nthreads 8 dump.bp", " ");	// bpmeta --nthreads 8 dump.bp
			sleep(1) =>
				setup_run(dir) => 
				(output2, exit_code2) = system(cmd2);

			if (exit_code2 != 0)
			{
				printf("swift: %s failed with exit code %d.", "bpmeta --nthreads 8 dump.bp", exit_code2);
			}
			else
			{
				int nwork3 = 2;
				string cmd3 = "../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";
				string args3[] = split("dump.bp adios_atom_voro.bp BP", " ");     // mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp BP
				string envs3[] = [ "OMP_NUM_THREADS=4", 
				       "swift_chdir="+dir, 
				       "swift_output="+dir/"output_voro_adios_omp_staging.txt", 
				       "swift_exectime="+dir/"time_voro_adios_omp_staging.txt", 
				       "swift_numproc=3",
				       "swift_ppw=2" ];

				printf("swift: launching with environment variables: %s", cmd3);
				sleep(1) =>
					setup_run(dir) =>
					exit_code3 = @par=nwork3 launch_envs(cmd3, args3, envs3);

				if (exit_code3 != 0)
				{
					printf("swift: %s failed with exit code %d.", cmd3, exit_code3);
				}
			}
		}
	}
}

