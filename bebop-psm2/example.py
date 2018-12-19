import rbfopt
import numpy as np
def obj_funct(x):
    return x[0]*x[1] - x[2]
bb = rbfopt.RbfoptUserBlackBox(3, np.array([0] * 3), np.array([10] * 3), np.array(['R', 'I', 'R']), obj_funct)
settings = rbfopt.RbfoptSettings(minlp_solver_path='/home/tshu/project/bebop/MPI_in_MPI/bebop-psm2/install/Bonmin-1.8.6/bin/cbc', max_evaluations=50)
alg = rbfopt.RbfoptAlgorithm(settings, bb)
objval, x, itercount, evalcount, fast_evalcount = alg.optimize()

