import numpy as np
import pandas as pd
from scipy.optimize import differential_evolution

import data

def obj_func_lv(x, *params):
    lmp_nproc = round(x[0])
    lmp_ppw = round(x[1])
    lmp_nthread = round(x[2])
    lmp_io_step = round(x[3]) * 50
    voro_nproc = round(x[4])
    voro_ppw = round(x[5])
    voro_nthread = round(x[6])
    x_chk = np.array([lmp_nproc, lmp_ppw, lmp_nthread, lmp_io_step, voro_nproc, voro_ppw, voro_nthread])
    y = float('inf')
    if (lmp_nproc >= lmp_ppw and voro_nproc >= voro_ppw):
        if (lmp_nproc % lmp_ppw == 0 and voro_nproc % voro_ppw == 0):
            nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw
        elif (lmp_nproc % lmp_ppw == 0 or voro_nproc % voro_ppw == 0):
            nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 1
        else:
            nodes = lmp_nproc // lmp_ppw + voro_nproc // voro_ppw + 2
        if (nodes <= data.node_num):
            if (len(params) == 4):
                mdl1_chk = params[0]
                mdl2_chk = params[1]
                mdl1 = params[2]
                mdl2 = params[3]
                
                x1_chk = x_chk[:4]
                x2_chk = np.hstack((x_chk[4:7], [x_chk[3]]))
                y1_chk = mdl1_chk.predict([x1_chk])[0]
                y2_chk = mdl2_chk.predict([x2_chk])[0]
                y_chk = min(y1_chk, y2_chk)
                if (y_chk > 0.0005):
                    y1 = mdl1.predict([x1_chk])[0]
                    y2 = mdl2.predict([x2_chk])[0]
                    y = 0.5 * (y1 + y2) + 0.5 * max(y1, y2)
                else:
                    y = float('inf')
            else:
                mdl_chk = params[0]
                mdl = params[1]
                
                y_chk = mdl_chk.predict([x_chk])[0]
                if (y_chk > 0.0005):
                    y = mdl.predict([x_chk])[0]
                else:
                    y = float('inf')
    return y

def pred_top_lv(mdls):
    bounds = [(2.0 - 0.1, (data.core_num - 1.0) * (data.node_num - 1.0) + 0.1), \
              (1.0 - 0.1, data.core_num - 1 + 0.1), \
              (1.0 - 0.1, 4.0 + 0.1), \
              (1.0 - 0.1, 8.0 + 0.1), \
              (2.0 - 0.1, (data.core_num - 1.0) * (data.node_num - 1.0) + 0.1), \
              (1.0 - 0.1, data.core_num - 1 + 0.1), \
              (1.0 - 0.1, 4.0 + 0.1)]
    result = differential_evolution(obj_func_lv, bounds, args=mdls)
    x = np.rint(result.x)
    if (len(mdls) == 4):
        y = obj_func_lv(x, mdls[0], mdls[1], mdls[2], mdls[3])
    else:
        y = obj_func_lv(x, mdls[0], mdls[1])
    x[3] *= 50
    smpl_arr = np.hstack((x, [y]))
    return smpl_arr

def obj_func_hs(x, *params):
    ht_x_nproc = round(x[0])
    ht_y_nproc = round(x[1])
    ht_ppw = round(x[2])
    ht_io_step = round(x[3]) * 4
    ht_io_buf = round(x[4])
    sw_nproc = round(x[5])
    sw_ppw = round(x[6])
    x_chk = np.array([ht_x_nproc, ht_y_nproc, ht_ppw, ht_io_step, ht_io_buf, sw_nproc, sw_ppw])
    y = float('inf')
    ht_nproc = ht_x_nproc * ht_y_nproc
    if (ht_nproc >= ht_ppw and sw_nproc >= sw_ppw):
        if (ht_nproc % ht_ppw == 0 and sw_nproc % sw_ppw == 0):
            nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw
        elif (ht_nproc % ht_ppw == 0 or sw_nproc % sw_ppw == 0):
            nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 1
        else:
            nodes = ht_nproc // ht_ppw + sw_nproc // sw_ppw + 2
        if (nodes <= data.node_num):
            if (len(params) == 4):
                mdl1_chk = params[0]
                mdl2_chk = params[1]
                mdl1 = params[2]
                mdl2 = params[3]
                
                x1_chk = x_chk[:5]
                x2_chk = np.hstack((x_chk[5:7], [x_chk[3]]))
                y1_chk = mdl1_chk.predict([x1_chk])[0]
                y2_chk = mdl2_chk.predict([x2_chk])[0]
                y_chk = min(y1_chk, y2_chk)
                if (y_chk > 0.0005):
                    y1 = mdl1.predict([x1_chk])[0]
                    y2 = mdl2.predict([x2_chk])[0]
                    y = 0.5 * (y1 + y2) + 0.5 * max(y1, y2)
                else:
                    y = float('inf')
            else:
                mdl_chk = params[0]
                mdl = params[1]
                
                y_chk = mdl_chk.predict([x_chk])[0]
                if (y_chk > 0.0005):
                    y = mdl.predict([x_chk])[0]
                else:
                    y = float('inf')
    return y

def pred_top_hs(mdls):
    bounds = [(2.0 - 0.1, 32.0 + 0.1), \
              (2.0 - 0.1, 32.0 + 0.1), \
              (1.0 - 0.1, data.core_num - 1 + 0.1), \
              (1.0 - 0.1, 8.0 + 0.1), \
              (1.0 - 0.1, 40.0 + 0.1), \
              (2.0 - 0.1, (data.core_num - 1.0) * (data.node_num - 1.0) + 0.1), \
              (1.0 - 0.1, data.core_num - 1 + 0.1)]
    result = differential_evolution(obj_func_hs, bounds, args=mdls)
    x = np.rint(result.x)
    if (len(mdls) == 4):
        y = obj_func_hs(x, mdls[0], mdls[1], mdls[2], mdls[3])
    else:
        y = obj_func_hs(x, mdls[0], mdls[1])
    x[3] *= 4
    smpl_arr = np.hstack((x, [y]))
    return smpl_arr

def pred_top_smpl(mdls, conf_colns, perf_coln, topn=10):
    slctR = 0.5
    cnddtn = int(float(topn) / slctR)
    app_name = data.get_name(conf_colns)
    for i in range(cnddtn):
        if (app_name == 'lv'):
            smpl_arr = pred_top_lv(mdls)
        elif (app_name == 'hs'):
            smpl_arr = pred_top_hs(mdls)

        if (i == 0):
            smpls_arr = smpl_arr
        else:
            smpls_arr = np.vstack((smpls_arr, smpl_arr))
    smpl_df = pd.DataFrame(np.c_[smpls_arr], columns=conf_colns + [perf_coln])
    top_smpl_df = smpl_df.drop_duplicates().sort_values([perf_coln]).reset_index(drop=True).head(topn)
    return top_smpl_df

