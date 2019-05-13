
# GA0 DEAP_GA

import json
import math
import os
import random
import sys
import threading
import time
import traceback

import glob, scipy, sklearn
import xgboost as xgb
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV

import eqpy
import data
import learn
import search

# Global variable names we are going to set from the JSON settings file
global_settings = ["HPC_app", "perf_coln", "core_num", "node_num", "rand_seed", "num_smpl", "pool_size", "num_iter", "prec_rand", "prec_init", "csv_file_name"]

def load_settings(settings_filename):
    print("Reading settings: '%s'" % settings_filename)
    try:
        with open(settings_filename) as fp:
            settings = json.load(fp)
    except IOError as e:
        print("Could not open: '%s'" % settings_filename)
        print("PWD is: '%s'" % os.getcwd())
        sys.exit(1)
    try:
        for s in global_settings:
            globals()[s] = settings[s]
        random.seed(rand_seed)
        data.core_num = core_num
        data.node_num = node_num
    except KeyError as e:
        print("Settings file (%s) does not contain key: %s" % (settings_filename, str(e)))
        sys.exit(1)
    print("HPC_app: %s, perf_coln: %s, core_num: %d, node_num: %d, rand_seed: %d, num_smpl: %d, pool_size: %d, num_iter: %d, prec_rand: %0.2f, prec_init: %0.2f, csv_file_name: %s" \
          % (HPC_app, perf_coln, core_num, node_num, rand_seed, num_smpl, pool_size, num_iter, prec_rand, prec_init, csv_file_name))
    print("Settings loaded.")

def run():
    """
    :HPC_app: HPC application
    :perf_coln: performance name to be optimized
    :param rand_seed: random seed
    :param num_smpl: number of samples
    :param pool_size: pool size
    :param num_iter: number of iterations
    :param prec_rand: precentage of random samples
    :param prec_init: precentage of initial samples replaced by equivalent samples
    :param csv_file_name: csv file name of test data set (e.g., "lmp_voro_time.csv")
    """
    eqpy.OUT_put("Settings")
    settings_filename = eqpy.IN_get()
    load_settings(settings_filename)
    if (HPC_app == "lv"):
        pool_df = data.gen_lv_smpl(pool_size, "lv_conf_pool.csv")
        conf_colns = data.lv_conf_colns 
    elif (HPC_app == "hs"):
        pool_df = data.gen_hs_smpl(pool_size, "hs_conf_pool.csv")
        conf_colns = data.hs_conf_colns

    conf_df = pool_df.head(num_smpl)
    eqpy.OUT_put(data.df2string(conf_df))
    result = eqpy.IN_get()
    time_df = data.string2df(result, ['run_time'])

    train_df = pd.concat([conf_df, time_df], axis=1)
    train_df = data.get_exec_mach_df(data.get_runnable_df(train_df, conf_colns))

    mdl_chk, mdl = learn.train_mdl_chk(train_df, conf_colns, perf_coln)

    top_pred_df = search.pred_top_smpl((mdl_chk, mdl, ), conf_colns, perf_coln)

    top_conf_df = top_pred_df[conf_colns].astype(int)
    eqpy.OUT_put(data.df2string(top_conf_df))
    result = eqpy.IN_get()
    time_df = data.string2df(result, ['run_time'])
    top_df = pd.concat([top_conf_df, time_df], axis=1)
    top_df = data.get_exec_mach_df(data.get_runnable_df(top_df, conf_colns))
    top_df = top_df.sort_values([perf_coln]).reset_index(drop=True)
    data.df2csv(top_df, HPC_app + "_top.csv")

    test_df = data.csv2df(csv_file_name, conf_colns)
    test_df = data.get_exec_mach_df(data.get_runnable_df(test_df, conf_colns))
    pred_top_smpl, err_prcntl_df, top_rs_df = learn.whl_pred_top_eval(train_df, test_df, conf_colns, perf_coln)
    data.df2csv(pred_top_smpl, HPC_app + "_top_test.csv")
    print top_rs_df, err_prcntl_df

    eqpy.OUT_put("FINAL")
    eqpy.OUT_put("{0}\n{1}".format(data.df2string(train_df), data.df2string(top_df)))

    #try:
    #except:
    #    traceback.print_exc()
    #    e = sys.exc_info()[0]
    #    print("%s", str(e))
    #context = fp.read()
    #settings = json.loads(context)

