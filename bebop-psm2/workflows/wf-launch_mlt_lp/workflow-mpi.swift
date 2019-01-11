import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string dir) "turbine" "0.0"
[
"""
	file mkdir <<dir>>
"""
];

(int exit_code) launch(string run_id, int params[])
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Worker counts
	int nworks[] = [2, 2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../../MPI/hello.x";
	cmds[1] = "../../../../../../MPI/hello.x";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	envs[0] = [ "OMP_NUM_THREADS="+int2string(params[1]), 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_hello1.txt", 
		"swift_exectime="+dir/"time_hello1.txt",
		"swift_numproc=%i" % params[0],
		"swift_ppw=2" ];
	envs[1] = [ "OMP_NUM_THREADS="+int2string(params[3]), 
		"swift_chdir="+dir, 
		"swift_output="+dir/"output_hello2.txt", 
		"swift_exectime="+dir/"time_hello2.txt",
		"swift_numproc=%i" % params[2],
		"swift_ppw=2" ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(nworks) launch_multi(nworks, cmds, args, envs);
}

main()
{
	int codes[];

	int params_start[] = [2, 2, 2, 2];
	int params_stop[] = [3, 3, 3, 3]; 
	int params_step[] = [1, 1, 1, 1];
	int params_num[] = [ (params_stop[0] - params_start[0]) %/ params_step[0] + 1,
	    (params_stop[1] - params_start[1]) %/ params_step[1] + 1,
	    (params_stop[2] - params_start[2]) %/ params_step[2] + 1,
	    (params_stop[3] - params_start[3]) %/ params_step[3] + 1 ];

	foreach param0 in [params_start[0] : params_stop[0] : params_step[0]]
	{
		foreach param1 in [params_start[1] : params_stop[1] : params_step[1]]
		{ 
			foreach param2 in [params_start[2] : params_stop[2] : params_step[2]]
			{
				foreach param3 in [params_start[3] : params_stop[3] : params_step[3]]
				{
					int i = (param0 - params_start[0]) %/ params_step[0] * params_num[1] * params_num[2] * params_num[3]
						+ (param1 - params_start[1]) %/ params_step[1] * params_num[2] * params_num[3]
						+ (param2 - params_start[2]) %/ params_step[2] * params_num[3]
						+ (param3 - params_start[3]) %/ params_step[3];
					codes[i] = launch("%0.2i_%0.2i_%0.2i_%0.2i" % (param0, param1, param2, param3), [param0, param1, param2, param3]);

					if (codes[i] != 0)
					{
						printf("swift: The multi-launched application with parameters (%d, %d, %d, %d) did not succeed with exit code: %d.",
								param0, param1, param2, param3, codes[i]);
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

