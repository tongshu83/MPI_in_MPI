import json
import threading
import time
import traceback

import common as cm
import data
import learn

def run():
    """
    :param app_name: HPC application
    :param perf_coln: performance name to be optimized
    :param num_core: number of CPU cores
    :param num_node: number of computing nodes
    :param rand_seed: random seed
    :param num_smpl: number of samples
    :param pool_size: pool size
    :param num_iter: number of iterations
    :param prec_rand: precentage of random samples
    :param prec_init: precentage of initial samples replaced by equivalent samples
    :param csv_file_name: csv file name of test data set (e.g., "lmp_voro_time.csv")
    """
    try:
        cm.init()
        app_name = cm.app_name
        perf_coln = cm.perf_coln
        num_smpl = cm.num_smpl

        if (app_name == "lv"):
            conf_colns = data.lv_conf_colns 
            conf_df = data.gen_lv_smpl(num_smpl)
            train_df = cm.measure_perf(conf_df, "LAMMPS_VORO++")
        elif (app_name == "hs"):
            conf_colns = data.hs_conf_colns
            conf_df = data.gen_hs_smpl(num_smpl)
            train_df = cm.measure_perf(conf_df, "HeatTransfer_StageWrite")

        mdl_chk, mdl = learn.train_mdl_chk(train_df, conf_colns, perf_coln)
        top_df = cm.find_top(mdl_chk, mdl, conf_colns, perf_coln)

        # cm.test(train_df, conf_colns, perf_coln, cm.csv_file_name)
        cm.finish(train_df, top_df)
    except:
         traceback.print_exc()

