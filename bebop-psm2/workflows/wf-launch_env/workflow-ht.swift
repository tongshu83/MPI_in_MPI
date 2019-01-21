import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_input(string dir, string infile) "turbine" "0.0"
[
"""
        file delete -force -- <<dir>>
        file mkdir <<dir>>
        cd <<dir>>
	file copy -force -- <<infile>> heat_transfer.xml
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
	string infile = "%s/heat_transfer.xml" % turbine_output;

	string cmd0[] = [ workflow_root/"ht.sh", "MPI", dir/"heat_transfer.xml" ];
	setup_input(dir, infile) =>
		(output0, exit_code0) = system(cmd0);

	if (exit_code0 != 0)
	{
		printf("swift: %s failed with exit code %d.", cmd0[0]+" "+cmd0[1]+" "+cmd0[2], exit_code0);
	}
	else
	{
		int nwork1 = 70;
		string cmd1 = "../../../../../Example-Heat_Transfer/heat_transfer_adios2"; 
		string args1[] = split("heat 10 7 40 50 6 5", " ");	// mpiexec -n 70 ./heat_transfer_adios2 heat 10 7 40 50 6 5
		string envs1[] = [ "OMP_NUM_THREADS=2", 
		       "swift_chdir="+dir, 
		       "swift_output="+dir/"output_heat_transfer_adios2.txt", 
		       "swift_exectime="+dir/"time_heat_transfer_adios2.txt", 
		       "swift_numproc=70", 
		       "swift_ppw=35" ];

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
				int nwork2 = 2;
				string cmd2 = "../../../../../Example-Heat_Transfer/stage_write/stage_write";
				string args2[] = split("heat.bp staged.bp FLEXPATH \"\" MPI \"\"", " ");     // mpiexec -n 70 stage_write/stage_write heat.bp staged.bp FLEXPATH "" MPI ""
				string envs2[] = [ "OMP_NUM_THREADS=2", 
				       "swift_chdir="+dir, 
				       "swift_output="+dir/"output_stage_write.txt", 
				       "swift_exectime="+dir/"time_stage_write.txt", 
				       "swift_numproc=70",
				       "swift_ppw=35" ];

				printf("swift: launching with environment variables: %s", cmd2);
				sleep(1) =>
					setup_run(dir) =>
					exit_code2 = @par=nwork2 launch_envs(cmd2, args2, envs2);

				if (exit_code2 != 0)
				{
					printf("swift: %s failed with exit code %d.", cmd2, exit_code2);
				}
		}
	}
}

