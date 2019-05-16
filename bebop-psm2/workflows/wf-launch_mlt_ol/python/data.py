import glob
import random
import numpy as np
import pandas as pd

num_core = 36
num_node = 32

lmp_conf_colns = ['lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step']
voro_conf_colns = ['voro_nproc', 'voro_ppw', 'voro_nthread', 'lmp_io_step']
lv_conf_colns = ['lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step', 'voro_nproc', 'voro_ppw', 'voro_nthread']
lv_in_conf_colns = ['lmp_l2s', 'lmp_sld', 'lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step', \
                    'voro_nproc', 'voro_ppw', 'voro_nthread']

ht_conf_colns = ['ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf']
sw_conf_colns = ['sw_nproc', 'sw_ppw', 'ht_io_step']
hs_conf_colns = ['ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf', 'sw_nproc', 'sw_ppw']
hs_in_conf_colns = ['ht_x', 'ht_y', 'ht_iter', 'ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf', \
                    'sw_nproc', 'sw_ppw']

# colns = df.columns.tolist()
def get_name(colns):
    if (all([x in colns for x in lv_in_conf_colns])):
        return 'lv_in'
    elif (all([x in colns for x in lv_conf_colns])):
        return 'lv'
    elif (all([x in colns for x in lmp_conf_colns])):
        return 'lmp'
    elif (all([x in colns for x in voro_conf_colns])):
        return 'voro'
    elif (all([x in colns for x in hs_in_conf_colns])):
        return 'hs_in'
    elif (all([x in colns for x in hs_conf_colns])):
        return 'hs'
    elif (all([x in colns for x in ht_conf_colns])):
        return 'ht'
    elif (all([x in colns for x in sw_conf_colns])):
        return 'sw'
    else:
        return 'unknown'

def df2string(df2D, super_delim=";", sub_delim=","):
    # super list elements separated by ;
    L = []
    for index, data in df2D.iterrows():
        L.append(sub_delim.join(str(n) for n in data.tolist()))
    result = super_delim.join(L)
    return result

def string2df(string, colns, super_delim=';', sub_delim=','):
    list_str = string.split(super_delim)
    arr2d = []
    for row in list_str:
        list_item = row.split(sub_delim)
        arr_item = np.array([float(i) for i in list_item])
        if (len(arr2d) == 0):
            arr2d = np.array([np.append(arr2d, arr_item)])
        else:
            arr2d = np.append(arr2d, [arr_item], axis=0)
    df = pd.DataFrame(arr2d, columns=colns)
    return df

def df2csv(df, csv_file_name):
    fp = open(csv_file_name, "w")
    fp.write(df.to_csv(sep='\t', header=False, index=False))
    fp.close()

def csv2df(csv_file_name, conf_colns):
    app_name = get_name(conf_colns)
    if (app_name == 'lv'):
        df = lv_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'lv_in'):
        df = lv_in_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'lmp'):
        df = lmp_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'voro'):
        df = voro_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'hs'):
        df = hs_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'hs_in'):
        df = hs_in_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'ht'):
        df = ht_load(glob.glob(csv_file_name), conf_colns)
    elif (app_name == 'sw'):
        df = sw_load(glob.glob(csv_file_name), conf_colns)
    df = df.sort_values(conf_colns).reset_index(drop=True)
    return df

def gen_lv_smpl(num_smpl, smpl_filename=''):
    random.seed(2019)
    lv_smpls = set([])
    while (len(lv_smpls) < num_smpl):
        lmp_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        lmp_ppw = random.randint(1, num_core - 1)
        lmp_nthread = random.randint(1, 4)
        lmp_io_step = random.randint(1, 8) * 50
        voro_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        voro_ppw = random.randint(1, num_core - 1)
        voro_nthread = random.randint(1, 4)
        
        if (lmp_nproc >= lmp_ppw and voro_nproc >= voro_ppw):
            if (lmp_nproc % lmp_ppw == 0 and voro_nproc % voro_ppw == 0):
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw
            elif (lmp_nproc % lmp_ppw == 0 or voro_nproc % voro_ppw == 0):
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 1
            else:
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 2
            if (nodes <= num_node):
                lv_smpls.add((lmp_nproc, lmp_ppw, lmp_nthread, lmp_io_step, voro_nproc, voro_ppw, voro_nthread))

    lv_smpls_df = pd.DataFrame(data = list(lv_smpls), \
                               columns=('lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step', \
                                        'voro_nproc', 'voro_ppw', 'voro_nthread'))
    if (smpl_filename != ''):
        df2csv(lv_smpls_df, smpl_filename)
    return lv_smpls_df

def gen_lv_smpl_in(num_smpl, smpl_filename=''):
    random.seed(2020)
    lv_smpls = set([])
    while (len(lv_smpls) < num_smpl):
        lmp_l2s = 16000 / (2 ** random.randint(0, 5))
        lmp_solid = 20000 / (2 ** random.randint(0, 5))
        lmp_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        lmp_ppw = random.randint(1, num_core - 1)
        lmp_nthread = random.randint(1, 4)
        lmp_io_step = random.randint(1, 8) * 50
        voro_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        voro_ppw = random.randint(1, num_core - 1)
        voro_nthread = random.randint(1, 4)
        
        if (lmp_nproc >= lmp_ppw and voro_nproc >= voro_ppw):
            if (lmp_nproc % lmp_ppw == 0 and voro_nproc % voro_ppw == 0):
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw
            elif (lmp_nproc % lmp_ppw == 0 or voro_nproc % voro_ppw == 0):
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 1
            else:
                nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 2
            if (nodes <= num_node):
                lv_smpls.add((lmp_l2s, lmp_solid, lmp_nproc, lmp_ppw, lmp_nthread, lmp_io_step, voro_nproc, voro_ppw, voro_nthread))

    smpls_df = pd.DataFrame(data = list(lv_smpls), \
                               columns=('lmp_l2s', 'lmp_solid', 'lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step', \
                                        'voro_nproc', 'voro_ppw', 'voro_nthread'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df

def gen_lmp_smpl(smpl_num, smpl_filename=''):
    random.seed(2021)
    smpls = set([])
    while (len(smpls) < smpl_num):
        lmp_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        lmp_ppw = random.randint(1, num_core - 1)
        lmp_nthread = random.randint(1, 4)
        lmp_io_step = random.randint(1, 8) * 50
        if (lmp_nproc >= lmp_ppw):
            if (lmp_nproc % lmp_ppw == 0):
                nodes = lmp_nproc // lmp_ppw
            else:
                nodes = lmp_nproc // lmp_ppw + 1
            if (nodes <= num_node - 1):
                smpls.add((lmp_nproc, lmp_ppw, lmp_nthread, lmp_io_step))
    smpls_df = pd.DataFrame(data = list(smpls), columns=('lmp_nproc', 'lmp_ppw', 'lmp_nthread', 'lmp_io_step'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df

def gen_voro_smpl(smpl_num, smpl_filename):
    random.seed(2022)
    smpls = set([])
    while (len(smpls) < smpl_num):
        voro_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        voro_ppw = random.randint(1, num_core - 1)
        voro_nthread = random.randint(1, 4)
        lmp_io_step = random.randint(1, 8) * 50
        if (voro_nproc >= voro_ppw):
            if (voro_nproc % voro_ppw == 0):
                nodes = voro_nproc // voro_ppw
            else:
                nodes = voro_nproc // voro_ppw + 1
            if (nodes <= num_node - 1):
                smpls.add((voro_nproc, voro_ppw, voro_nthread, lmp_io_step))
    smpls_df = pd.DataFrame(data = list(smpls), columns=('voro_nproc', 'voro_ppw', 'voro_nthread', 'lmp_io_step'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df     

def lmp_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()])
    return pd.DataFrame(val, columns=colns)

def voro_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()])
    return pd.DataFrame(val, columns=colns)

def lv_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()[:len(colns)]])
    return pd.DataFrame(val, columns=colns)

def lv_in_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn): 
            val.append([float(s) for s in l.split()[:len(colns)]])
    return pd.DataFrame(val, columns=colns)

def gen_hs_smpl(num_smpl, smpl_filename=''):
    random.seed(2019)
    hs_smpls = set([])
    while (len(hs_smpls) < num_smpl):
        ht_x_nproc = random.randint(2, 32)
        ht_y_nproc = random.randint(2, 32)
        ht_ppw = random.randint(1, num_core - 1)
        ht_io_step = random.randint(1, 8) * 4
        ht_io_buf = random.randint(1, 40)
        sw_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        sw_ppw = random.randint(1, num_core - 1)
        
        ht_nproc = ht_x_nproc * ht_y_nproc
        if (ht_nproc >= ht_ppw and sw_nproc >= sw_ppw):
            if (ht_nproc % ht_ppw == 0 and sw_nproc % sw_ppw == 0):
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw
            elif (ht_nproc % ht_ppw == 0 or sw_nproc % sw_ppw == 0):
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 1
            else:
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 2
            if (nodes <= num_node):
                hs_smpls.add((ht_x_nproc, ht_y_nproc, ht_ppw, ht_io_step, ht_io_buf, sw_nproc, sw_ppw))

    hs_smpls_df = pd.DataFrame(data = list(hs_smpls), \
                               columns=('ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf', \
                                        'sw_nproc', 'sw_ppw'))
    if (smpl_filename != ''):
        df2csv(hs_smpls_df, smpl_filename)
    return hs_smpls_df

def gen_hs_smpl_in(num_smpl, smpl_filename=''):
    random.seed(2020)
    hs_smpls = set([])
    while (len(hs_smpls) < num_smpl):
        ht_x = 2048 / (2 ** random.randint(0, 5))
        ht_y = 2048 / (2 ** random.randint(0, 5))
        ht_iter = 1024 / (2 ** random.randint(0, 5))
        ht_x_nproc = random.randint(2, 32)
        ht_y_nproc = random.randint(2, 32)
        ht_ppw = random.randint(1, num_core - 1)
        ht_io_step = random.randint(1, 8) * 4
        ht_io_buf = random.randint(1, 40)
        sw_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        sw_ppw = random.randint(1, num_core - 1)
        
        ht_nproc = ht_x_nproc * ht_y_nproc
        if (ht_nproc >= ht_ppw and sw_nproc >= sw_ppw):
            if (ht_nproc % ht_ppw == 0 and sw_nproc % sw_ppw == 0):
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw
            elif (ht_nproc % ht_ppw == 0 or sw_nproc % sw_ppw == 0):
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 1
            else:
                nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 2
            if (nodes <= num_node):
                hs_smpls.add((ht_x, ht_y, ht_iter, ht_x_nproc, ht_y_nproc, ht_ppw, ht_io_step, ht_io_buf, \
                              sw_nproc, sw_ppw))

    smpls_df = pd.DataFrame(data = list(hs_smpls), \
                               columns=('ht_x', 'ht_y', 'ht_iter', \
                                        'ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf', \
                                        'sw_nproc', 'sw_ppw'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df

def gen_ht_smpl(smpl_num, smpl_filename=''):
    random.seed(2021)
    smpls = set([])
    while (len(smpls) < smpl_num):
        ht_x_nproc = random.randint(2, 32)
        ht_y_nproc = random.randint(2, 32)
        ht_ppw = random.randint(1, num_core - 1)
        ht_io_step = random.randint(1, 8) * 4
        ht_io_buf = random.randint(1, 40)
        
        ht_nproc = ht_x_nproc * ht_y_nproc
        if (ht_nproc >= ht_ppw):
            if (ht_nproc % ht_ppw == 0):
                nodes = ht_nproc // ht_ppw
            else:
                nodes = ht_nproc // ht_ppw + 1
            if (nodes <= num_node - 1):
                smpls.add((ht_x_nproc, ht_y_nproc, ht_ppw, ht_io_step, ht_io_buf))
    smpls_df = pd.DataFrame(data = list(smpls), \
                            columns=('ht_x_nproc', 'ht_y_nproc', 'ht_ppw', 'ht_io_step', 'ht_io_buf'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df

def gen_sw_smpl(smpl_num, smpl_filename=''):
    random.seed(2022)
    smpls = set([])
    while (len(smpls) < smpl_num):
        sw_nproc = random.randint(2, (num_core - 1) * (num_node - 1))
        sw_ppw = random.randint(1, num_core - 1)
        ht_io_step = random.randint(1, 8) * 4
        
        if (sw_nproc >= sw_ppw):
            if (sw_nproc % sw_ppw == 0):
                nodes = sw_nproc // sw_ppw
            else:
                nodes = sw_nproc // sw_ppw + 1
            if (nodes <= num_node - 1):
                smpls.add((sw_nproc, sw_ppw, ht_io_step))
    smpls_df = pd.DataFrame(data = list(smpls), columns=('sw_nproc', 'sw_ppw', 'ht_io_step'))
    if (smpl_filename != ''):
        df2csv(smpls_df, smpl_filename)
    return smpls_df

def ht_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()])
    return pd.DataFrame(val, columns=colns)

def sw_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()])
    return pd.DataFrame(val, columns=colns)

def hs_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn):
            val.append([float(s) for s in l.split()[:len(colns)]])
    return pd.DataFrame(val, columns=colns)

def hs_in_load(fns, conf_colns, perfn='run_time'):
    if (perfn == ''):
        colns = conf_colns
    else:
        colns = conf_colns + [perfn]
    val = []
    for fn in fns:
        for l in open(fn): 
            val.append([float(s) for s in l.split()[:len(colns)]])
    return pd.DataFrame(val, columns=colns)

def get_runnable_df(df, conf_colns, perf_coln='run_time'):
    arr = np.ones(df.shape[0])
    for i in range(df.shape[0]):
        if (df[perf_coln].values[i] == float('inf')):
            arr[i] = 0.0
    rem_colns = [i for i in df.columns.tolist() if i not in conf_colns]
    vld_df = pd.DataFrame(np.c_[df[conf_colns].values, arr, df[rem_colns].values], \
                          columns=conf_colns + ['runnable'] + rem_colns)
    return vld_df

def get_mach_time(nproc, ppn, runtime):
    nnode = np.negative(np.floor_divide(np.negative(nproc), ppn))
    mach_time = np.multiply(nnode, runtime) * num_core / 3600
    return mach_time

def get_exec_mach_df(exec_df):
    if ('run_time' not in exec_df.columns.tolist()):
        print "Error: there is no information on exection time!"
        return exec_df

    if ('mach_time' in exec_df.columns.tolist()):
        return exec_df

    df_name = get_name(exec_df.columns.tolist())
    if (df_name != 'lmp' and df_name != 'voro' and df_name != 'lv' and df_name != 'lv_in' \
        and df_name != 'ht' and df_name != 'sw' and df_name != 'hs' and df_name != 'hs_in'):
        print "Error: unknown dataframe!"
        return exec_df
    
    runtime = exec_df['run_time'].values
    if (df_name == 'lmp' or df_name == 'voro' or df_name == 'ht' or df_name == 'sw'):
        if (df_name == 'lmp'):
            nproc = exec_df['lmp_nproc'].values
            ppn = exec_df['lmp_ppw'].values
        elif (df_name == 'voro'):
            nproc = exec_df['voro_nproc'].values
            ppn = exec_df['voro_ppw'].values
        elif (df_name == 'ht'):
            nproc = exec_df['ht_x_nproc'].values * exec_df['ht_y_nproc'].values
            ppn = exec_df['ht_ppw'].values
        else:
            nproc = exec_df['sw_nproc'].values
            ppn = exec_df['sw_ppw'].values
        mach_time = get_mach_time(nproc, ppn, runtime)
    else:
        if (df_name == 'lv' or df_name == 'lv_in'):
            sim_nproc = exec_df['lmp_nproc'].values
            sim_ppn = exec_df['lmp_ppw'].values
            anal_nproc = exec_df['voro_nproc'].values
            anal_ppn = exec_df['voro_ppw'].values
        else:
            sim_nproc = exec_df['ht_x_nproc'].values * exec_df['ht_y_nproc'].values
            sim_ppn = exec_df['ht_ppw'].values
            anal_nproc = exec_df['sw_nproc'].values
            anal_ppn = exec_df['sw_ppw'].values
        mach_time = get_mach_time(sim_nproc, sim_ppn, runtime) + get_mach_time(anal_nproc, anal_ppn, runtime)
    
    exec_mach_df = pd.DataFrame(np.c_[exec_df.values, mach_time], columns=exec_df.columns.tolist() + ['mach_time'])
    return exec_mach_df

