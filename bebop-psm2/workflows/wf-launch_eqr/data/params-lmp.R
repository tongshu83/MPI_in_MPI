
# PARAMS
# Set search space parameters for mlrMBO

param.set <- makeParamSet(
		# LAMMPS: the number of processes
		makeIntegerParam("lammps_proc", lower = 1, upper = 16),
		# VORO: the number of processes
		makeIntegerParam("voro_proc", lower = 1, upper = 16)
	)

