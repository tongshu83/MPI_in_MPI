import io;
import files;
import launch;
import stats;
import string;
import sys;

import assert;                  
import json;    
import location;
import math;

import R;
import EQR;             

string workflow_root = getenv("WORKFLOW_ROOT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");
string param_set = argv("param_set_file");
int max_budget = toint(argv("mb", "110"));
int max_iterations = toint(argv("it", "10"));
int design_size = toint(argv("ds", "10"));
int propose_points = toint(argv("pp", "3"));

(void v) setup_run(string dir) "turbine" "0.0"
[
"""
file mkdir <<dir>>
"""
];

(string result) launch(string run_id, string params)
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);

	// Process counts
	int proc1 = string2int(json_get(params, "proc1"));
	int proc2 = string2int(json_get(params, "proc2"));
	int procs[] = [proc1, proc2];

	// Commands
	string cmds[];
	cmds[0] = "../../../../../../scripts/script1.sh";
	cmds[1] = "../../../../../../scripts/script2.sh";

	// Command line arguments
	string args[][];
	args[0] = [""];
	args[1] = [""];

	// Environment variables
	string envs[][];
	envs[0] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script1.txt", "swift_exectime="+dir/"time_script1.txt" ];
	envs[1] = [ "swift_chdir="+dir, "swift_output="+dir/"output_script2.txt", "swift_exectime="+dir/"time_script2.txt" ];

	printf("swift: multiple launching: %s, %s", cmds[0], cmds[1]);
	setup_run(dir) =>
		exit_code = @par=sum_integer(procs) launch_multi(procs, cmds, args, envs);

	float exectime;
	if (exit_code == 0) {
		string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_script*.txt" ];
		sleep(1) =>
			(time_output, time_exit_code) = system(cmd);
		if (time_exit_code == 0) {
			exectime = string2float(time_output);
			if (exectime >= 0.0) {
				printf("exectime(%i, %i): %f", proc1, proc2, exectime);
				string output = "%0.1i\t%0.1i\t%f\t" % (proc1, proc2, exectime);
				file out <dir/"time.txt"> = write(output);
			} else {
				printf("swift: The execution time (%f seconds) of the multi-launched application with parameters (%d, %d) is negative.", exectime, proc1, proc2);
			}
		} else {
			exectime = -1.0;
			printf("swift: Failed to get the execution time of the multi-launched application of parameters (%d, %d) with exit code: %d.\n%s", proc1, proc2, time_exit_code, time_output);
		}
	} else {
		exectime = -1.0;
		printf("swift: The multi-launched application with parameters (%d, %d) did not succeed with exit code: %d.", proc1, proc2, exit_code);
	}
	result = float2string(exectime);
}

(void v) loop(location ME)
{
	for (boolean b = true, int i = 1; 
			b; 
			b=c, i = i + 1)
	{
		string params =  EQR_get(ME);
		printf("params: %s", params);
		boolean c;

		if (params == "DONE")
		{
			// We are done: store the final results
			// string finals =  EQR_get(ME);
			string turbine_output = getenv("TURBINE_OUTPUT");
			string fname = "%s/final_res.Rds" % (turbine_output);
			printf("See results in %s", fname) =>
				// printf("Results: %s", finals) =>
				v = make_void() =>
				c = false;
		}
		else if (params == "EQR_ABORT")
		{
			printf("EQR aborted: see output for R error") =>
				string why = EQR_get(ME);
			printf("%s", why) =>
				v = propagate() =>
				c = false;
		}
		else
		{
			string param_array[] = split(params, ";");
			string result[];
			foreach p, j in param_array
			{
				result[j] = launch("%0.2i_%0.2i" % (i, j), p);
			}
			string results = join(result, ";");
			printf("results: %s", results);
			EQR_put(ME, results) => c = true;
		}
	}
}

// These must agree with the arguments to the objective function in mlrMBO3.R,
// except param.set.file is removed and processed by the mlrMBO.R algorithm wrapper.
string algo_params_template =
"""
param.set.file='%s',
	max.budget = %d,
	max.iterations = %d,
	design.size=%d,
	propose.points=%d
	""";

	(void o) start(int ME_rank) {
		location ME = locationFromRank(ME_rank);

		// algo_params is the string of parameters used to initialize the
		// R algorithm. We pass these as R code: a comma separated string
		// of variable=value assignments.
		string algo_params = algo_params_template %
			(param_set, max_budget, max_iterations,
			 design_size, propose_points);
		string algorithm = workflow_root/"mlrMBO3.R";
		EQR_init_script(ME, algorithm) =>
			EQR_get(ME) =>
			EQR_put(ME, algo_params) =>
			loop(ME) => {
				EQR_stop(ME) =>
					EQR_delete_R(ME);
				o = propagate();
			}
	}


main() {
	printf("turbine workers: %i", turbine_workers());
//	assert(strlen(workflow_root) > 0, "Set WORKFLOW_ROOT!");

	int ME_ranks[];
	foreach r_rank, i in r_ranks{
		ME_ranks[i] = toint(r_rank);
	}

	foreach ME_rank, i in ME_ranks {
		start(ME_rank) =>
			printf("End rank: %d", ME_rank);
	}
}

