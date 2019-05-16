import json
import os
import pandas as pd
import random
import sys

import data
import eqpy
import learn
import search

# Global variable names we are going to set from the JSON settings file
global_settings = ["app_name", "perf_coln", "num_core", "num_node", "rand_seed", "num_smpl", "pool_size", "num_iter", "prec_rand", "prec_init", "csv_file_name"]

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
            print("%s: %s" % (s, str(settings[s])))
        random.seed(rand_seed)
        data.num_core = num_core
        data.num_node = num_node
    except KeyError as e:
        print("Settings file (%s) does not contain key: %s" % (settings_filename, str(e)))
        sys.exit(1)
    print("Settings loaded.")

def init():
    eqpy.OUT_put("Settings")
    settings_filename = eqpy.IN_get()
    load_settings(settings_filename)

def init_pool():
    init()
    if (app_name == "lv"):
        conf_colns = data.lv_conf_colns 
        pool_df = data.gen_lv_smpl(pool_size, "lv_conf_pool.csv")
    elif (app_name == "hs"):
        conf_colns = data.hs_conf_colns
        pool_df = data.gen_hs_smpl(pool_size, "hs_conf_pool.csv")
    return conf_colns, pool_df

def measure_perf(conf_df, type_smpl):
    conf_colns = conf_df.columns.tolist()
    conf_df = conf_df.astype(int)
    eqpy.OUT_put(type_smpl)
    eqpy.OUT_put(data.df2string(conf_df))
    result = eqpy.IN_get()
    time_df = data.string2df(result, ['run_time'])
    conf_perf_df = pd.concat([conf_df, time_df], axis=1)
    conf_perf_df = data.get_exec_mach_df(data.get_runnable_df(conf_perf_df, conf_colns))
    return conf_perf_df

def find_top(mdl_chk, mdl, conf_colns, perf_coln):
    top_pred_df = search.get_pred_top_smpl((mdl_chk, mdl, ), conf_colns, perf_coln)
    top_conf_df = top_pred_df[conf_colns]
    top_df = measure_perf(top_conf_df, "LAMMPS_VORO++")
    top_df = top_df.sort_values([perf_coln]).reset_index(drop=True)
    data.df2csv(top_df, app_name + "_top.csv")
    return top_df

def test(train_df, conf_colns, perf_coln, csv_file_name):
    test_df = data.csv2df(csv_file_name, conf_colns)
    test_df = data.get_exec_mach_df(data.get_runnable_df(test_df, conf_colns))
    pred_top_smpl, err_prcntl_df, top_rs_df = learn.whl_pred_top_eval(train_df, test_df, conf_colns, perf_coln)
    data.df2csv(pred_top_smpl, app_name + "_top_test.csv")
    print top_rs_df, err_prcntl_df

def finish(train_df, top_df):
    eqpy.OUT_put("FINAL")
    eqpy.OUT_put("{0}\n{1}".format(data.df2string(train_df), data.df2string(top_df)))

