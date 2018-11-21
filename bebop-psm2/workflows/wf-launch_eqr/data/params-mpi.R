
# PARAMS
# Set search space parameters for mlrMBO

param.set <- makeParamSet(
		# Hello1: the number of processes
		makeIntegerParam("proc1", lower = 2, upper = 6),
		# Hello2: the number of processes
		makeIntegerParam("proc2", lower = 2, upper = 6)
	)

