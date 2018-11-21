
# PARAMS
# Set search space parameters for mlrMBO

param.set <- makeParamSet(
		# Heat Transfer: the number of processes in Dimension X
		makeIntegerParam("ht_proc_x", lower = 1, upper = 5),
		# Heat Transfer: the number of processes in Dimension Y
		makeIntegerParam("ht_proc_y", lower = 1, upper = 5),
		# Stage Write: the number of processes
		makeIntegerParam("sw_proc", lower = 1, upper = 7)
	)

