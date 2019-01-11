import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_input(string dir, string infile1, string infile2, string infile3) "turbine" "0.0"
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

(void v) setup_run(string dir) "turbine" "0.0"
[
"""
	cd <<dir>>
"""
];

(int exit_code) launch(string run_id, int params[])
{
	int lmp_proc = params[0];       // Lammps: total num of processes
	int lmp_ppw = params[1];        // Lammps: num of processes per worker
	int lmp_thrd = params[2];       // Lammps: num of threads per process
	int lmp_frqIO = params[3];      // Lammps: IO interval in steps
	int voro_proc = params[4];      // Voro: total num of processes
	int voro_ppw = params[5];       // Voro: num of processes per worker
	int voro_thrd = params[6];      // Voro: num of threads per process

	string workflow_root = getenv("WORKFLOW_ROOT");
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string infile1 = "%s/in.quench.short" % turbine_output;
	string infile2 = "%s/restart.liquid" % turbine_output;
	string infile3 = "%s/CuZr.fs" % turbine_output;

	string cmd0[] = [ workflow_root/"lmp.sh", int2string(lmp_frqIO), "POSIX", dir/"in.quench.short" ];
	setup_input(dir, infile1, infile2, infile3) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0);
		exit_code = exit_code0;
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
		string args1[] = split("-i in.quench.short", " ");	// mpiexec -n 8 ./lmp_mpi -i in.quench.short
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
			printf("swift: %s failed with exit code %d.", cmd1, exit_code1);
			exit_code = exit_code1;
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
				exit_code = exit_code2;
			}
			else
			{
				int nwork3;
				if (voro_proc %% voro_ppw == 0) {
					nwork3 = voro_proc %/ voro_ppw;
				} else {
					nwork3 = voro_proc %/ voro_ppw + 1;
				}
				string cmd3 = "../../../../../../Example-LAMMPS/swift-all/voro_adios_omp_staging";
				string args3[] = split("dump.bp adios_atom_voro.bp BP", " ");     // mpiexec -n 4 ./voro_adios_omp_staging dump.bp adios_atom_voro.bp BP
				string envs3[] = [ "OMP_NUM_THREADS="+int2string(voro_thrd), 
				       "swift_chdir="+dir, 
				       "swift_output="+dir/"output_voro_adios_omp_staging.txt", 
				       "swift_exectime="+dir/"time_voro_adios_omp_staging.txt", 
				       "swift_numproc=%i" % voro_proc, 
				       "swift_ppw=%i" % voro_ppw ];

				printf("swift: launching with environment variables: %s", cmd3);
				sleep(1) =>
					exit_code3 = @par=nwork3 launch_envs(cmd3, args3, envs3);

				if (exit_code3 != 0)
				{
					printf("swift: %s failed with exit code %d.", cmd3, exit_code3);
					exit_code = exit_code3;
				}
				else
				{
					exit_code = 0;
				}
			}
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
	// 4) Voro: total num of processes
	// 5) Voro: num of processes per worker
	// 6) Voro: num of threads per process
	int params_start[] = [34, 17, 2, 100, 34, 17, 2];
	int params_stop[] = [34, 34, 2, 200, 34, 34, 2];
	int params_step[] = [34, 17, 1, 100, 34, 17, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1,
	    (params_stop[4] - params_start[4]) %/ params_step[4] + 1,
	    (params_stop[5] - params_start[5]) %/ params_step[5] + 1,
	    (params_stop[6] - params_start[6]) %/ params_step[6] + 1 ];

	int codes[];
	foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
	{
		if (param1 <= ppw)
		{
			foreach param5 in [params_start[5] : params_stop[5] : params_step[5]]
			{
				if (param5 <= ppw)
				{
					foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
					{
						int nwork1;
						if (param0 %% param1 == 0) {
							nwork1 = param0 %/ param1;
						} else {
							nwork1 = param0 %/ param1 + 1;
						}
						if (nwork1 <= workers)
						{
							foreach param4 in [params_start[4] : params_stop[4] : params_step[4]]
							{
								int nwork2;
								if (param4 %% param5 == 0) {
									nwork2 = param4 %/ param5;
								} else {
									nwork2 = param4 %/ param5 + 1;
								}
								if (nwork2 <= workers)
								{
									foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
									{
										foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
										{
											foreach param6 in [params_start[6] : params_stop[6] : params_step[6]]
											{
												int i = (param0 - params_start[0]) %/ params_step[0]
													* params_num[1] * params_num[2] * params_num[3] * params_num[4] * params_num[5] * params_num[6]
													+ (param1 - params_start[1]) %/ params_step[1]
													* params_num[2] * params_num[3] * params_num[4] * params_num[5] * params_num[6]
													+ (param2 - params_start[2]) %/ params_step[2]
													* params_num[3] * params_num[4] * params_num[5] * params_num[6]
													+ (param3 - params_start[3]) %/ params_step[3]
													* params_num[4] * params_num[5] * params_num[6]
													+ (param4 - params_start[4]) %/ params_step[4]
													* params_num[5] * params_num[6]
													+ (param5 - params_start[5]) %/ params_step[5]
													* params_num[6]
													+ (param6 - params_start[6]) %/ params_step[6];
												codes[i] = launch("%0.2i_%0.2i_%0.1i_%0.3i_%0.2i_%0.2i_%0.1i"
														% (param0, param1, param2, param3, param4, param5, param6),
														[param0, param1, param2, param3, param4, param5, param6]);

												if (codes[i] != 0)
												{
													printf("swift: The launched applications with parameters (%d, %d, %d, %d, %d, %d, %d)
															did not succeed with exit code: %d.",
															param0, param1, param2, param3, param4, param5, param6, codes[i]);
												}
											}
										}
									}
								}
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

