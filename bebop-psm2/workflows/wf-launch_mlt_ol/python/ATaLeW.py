import pandas as pd
import threading
import traceback

import common as cm
import data
import learn
import tool

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
    :param csv_file_name: csv file name of test data set (e.g., "lv_time.csv")
    """
    try:
        cm.init()
        app_name = cm.app_name
        perf_coln = cm.perf_coln
        num_smpl = cm.num_smpl
        pool_size = cm.pool_size
        num_iter = cm.num_iter
        prec_rand = cm.prec_rand
        prec_init = cm.prec_init
    
        if (app_name == "lv"):
            conf_colns = data.lv_conf_colns
            in_conf_colns = data.lv_in_conf_colns
            in_params = data.lmp_in_params 
        elif (app_name == "hs"):
            conf_colns = data.hs_conf_colns
            in_conf_colns = data.hs_in_conf_colns
            in_params = data.ht_in_params

        pool_df = data.gen_smpl(app_name, pool_size)
        num_rand = int(num_smpl * prec_rand)
        conf_df = pool_df.head(num_rand)

        in_colns = [i for i in in_conf_colns if i not in conf_colns]
        in_conf_df = tool.df_ext(conf_df, in_colns, in_params)

        num_init = int(num_smpl * prec_init)
        in_pool_df = data.gen_smpl(cm.app_in_name(app_name), num_init * 100)
        in_pool_df = pd.concat([in_pool_df, in_conf_df]).drop_duplicates(keep=False).reset_index(drop=True)
        in_conf_df = pd.concat([in_conf_df, in_pool_df.head(num_init)]).reset_index(drop=True)
        in_df = cm.measure_perf(in_conf_df)

        train_df = tool.df_filter(in_df, in_colns, in_params)
        avg_mach_time = data.sa_mach_time(train_df) / train_df.shape[0]

        init_df = tool.df_intersection(in_df, in_pool_df.head(num_init), in_conf_colns)
        avg_in_mach_time = data.sa_mach_time(init_df) / num_init

        factor = max(1, avg_mach_time / avg_in_mach_time)
        num = int(num_init * factor)
	if (num > num_init):
            new_in_conf_df = in_pool_df.head(num).tail(num - num_init)
            new_in_df = cm.measure_perf(new_in_conf_df)
            in_df = pd.concat([in_df, new_in_df]).reset_index(drop=True)

        pred_top_smpl = learn.whl_in_pred_top_eval(in_df, pool_df, in_params, in_conf_colns, conf_colns, perf_coln, num_smpl, 0)

        train_df = tool.df_filter(in_df, in_colns, in_params)
        conf_df = train_df[conf_colns]
        incr_num = train_df.shape[0] - num_rand
        nspi = int((num_smpl - num_init - num_rand) / num_iter)
    
        for iter_idx in range(num_iter):
            num_curr = num_smpl - num_init - nspi * (num_iter - 1 - iter_idx)

            pred_top_smpl = pred_top_smpl.sort_values([perf_coln]).reset_index(drop=True)
            new_conf_df = pred_top_smpl[conf_colns].head(nspi)
            conf_df = pd.concat([conf_df, new_conf_df]).drop_duplicates().reset_index(drop=True)

            last = nspi
            while (conf_df.shape[0] < num_curr + incr_num):
                last = last + 1
                new_conf_df = pred_top_smpl[conf_colns].head(last)
                conf_df = pd.concat([conf_df, new_conf_df]).drop_duplicates().reset_index(drop=True)

            new_train_df = cm.measure_perf(new_conf_df)
            train_df = pd.concat([train_df, new_train_df]).reset_index(drop=True)
            if (iter_idx < num_iter - 1):
                pred_top_smpl = learn.whl_pred_top_eval(train_df, pool_df, conf_colns, perf_coln, num_smpl, 0)

        mdl_chk, mdl = learn.train_mdl_chk(train_df, conf_colns, perf_coln)
        top_df = cm.find_top('ATaLeW', (mdl_chk, mdl, ), conf_colns, perf_coln)
    
        # cm.test(train_df, conf_colns, perf_coln, cm.csv_file_name)
        cm.finish(train_df, top_df)
    except:
        traceback.print_exc()

