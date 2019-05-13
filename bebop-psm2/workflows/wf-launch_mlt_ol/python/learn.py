import numpy as np
import pandas as pd
import xgboost as xgb

import tool

def train_mdl(train_df, conf_colns, perf_coln):
    train_X = train_df[conf_colns].values
    train_y = train_df[perf_coln].values
    mdl = xgb.XGBRegressor(max_depth=10, n_estimators=200).fit(train_X, train_y)
    return mdl

def train_mdl_chk(train_df, conf_colns, perf_coln):
    mdl_chk = train_mdl(train_df, conf_colns, 'runnable')
    train_df_vld = tool.get_vld_df(train_df)
    mdl = train_mdl(train_df_vld, conf_colns, perf_coln)
    return mdl_chk, mdl

def sprt_cmb_pred_vld(pred_y1, pred_y2):
    pred_y = np.concatenate(([pred_y1], [pred_y2]), axis=0).min(axis=0)
    return pred_y

def sprt_cmb_pred_val(pred_y1, pred_y2, perf_coln):
    if (perf_coln == 'run_time'):
        pred_y = 0.5 * (pred_y1 + pred_y2) + 0.5 * np.concatenate(([pred_y1], [pred_y2]), axis=0).max(axis=0)
    elif (perf_coln == 'mach_time'):
        pred_y = pred_y1 + pred_y2
    else:
        pred_y = np.concatenate(([pred_y1], [pred_y2]), axis=0).max(axis=0)
    return pred_y

def sprt_pred_chk(mdl1_chk, mdl2_chk, test_df, conf1_colns, conf2_colns, conf_colns):
    test_X1_chk = test_df[conf1_colns].values
    test_X2_chk = test_df[conf2_colns].values
    pred_y1_chk = mdl1_chk.predict(test_X1_chk)
    pred_y2_chk = mdl2_chk.predict(test_X2_chk)
    pred_y_chk = sprt_cmb_pred_vld(pred_y1_chk, pred_y2_chk)
    for i in range(test_df.shape[0]):
        if (pred_y_chk[i] > 0.0005):
            pred_y_chk[i] = 1.0
        else:
            pred_y_chk[i] = 0.0
    pred_df_chk = pd.DataFrame(np.c_[test_df[conf_colns].values, pred_y_chk], columns=conf_colns + ['runnable'])
    return pred_df_chk
    
def sprt_pred_val(pred_df_chk, mdl1, mdl2, test_df, conf1_colns, conf2_colns, conf_colns, perf_coln):
    test_df_vld = tool.get_vld_df(test_df)
    test_X1_vld = test_df_vld[conf1_colns].values
    test_X2_vld = test_df_vld[conf2_colns].values
    pred_y1_vld = mdl1.predict(test_X1_vld)
    pred_y2_vld = mdl2.predict(test_X2_vld)
    pred_y_vld = sprt_cmb_pred_val(pred_y1_vld, pred_y2_vld, perf_coln)
    pred_df_vld = pd.DataFrame(np.c_[test_df_vld[conf_colns].values, pred_y_vld], columns=conf_colns + [perf_coln])
    
    pred_df = pred_df_chk[(pred_df_chk.runnable == 1.0)]
    test_X1 = pred_df[conf1_colns].values
    test_X2 = pred_df[conf2_colns].values
    pred_y1 = mdl1.predict(test_X1)
    pred_y2 = mdl2.predict(test_X2)
    pred_y = sprt_cmb_pred_val(pred_y1, pred_y2, perf_coln)
    pred_df = pd.DataFrame(np.c_[pred_df[conf_colns].values, pred_y], columns=conf_colns + [perf_coln])
    pred_df_invld = pred_df_chk[(pred_df_chk.runnable == 0.0)]
    pred_y = pred_df_invld['runnable'].values + np.ones(pred_df_invld.shape[0]) * float('inf')
    pred_df_invld = pd.DataFrame(np.c_[pred_df_invld[conf_colns].values, pred_y], columns=conf_colns + [perf_coln])
    pred_df = pred_df.append(pred_df_invld)
    return pred_df, pred_df_vld
    
def sprt_pred_top_eval(train_df1, train_df2, test_df, conf1_colns, conf2_colns, conf_colns, perf_coln, \
                       topn=1, eval_flag=1):
    mdl1_chk, mdl1 = train_mdl_chk(train_df1, conf1_colns, perf_coln)
    mdl2_chk, mdl2 = train_mdl_chk(train_df2, conf2_colns, perf_coln)
    
    pred_df_chk = sprt_pred_chk(mdl1_chk, mdl2_chk, test_df, conf1_colns, conf2_colns, conf_colns)
    test_df_vld = tool.get_vld_df(test_df)
    
    if (perf_coln != 'obj'):
        pred_df, pred_df_vld = sprt_pred_val(pred_df_chk, mdl1, mdl2, test_df, \
                                             conf1_colns, conf2_colns, conf_colns, perf_coln)
    else:
        obj_vld_arr = np.zeros(test_df_vld.shape[0])
        obj_arr = np.zeros(test_df.shape[0])
        for i in range(len(obj_perf_colns)):
            pred_df, pred_df_vld = sprt_pred_val(pred_df_chk, mdl1, mdl2, test_df, \
                                                 conf1_colns, conf2_colns, conf_colns, obj_perf_colns[i])
            mean_val = test_df_vld[obj_perf_colns[i]].values.mean()
            obj_vld_arr += obj_weights[i] * pred_df_vld[obj_perf_colns[i]].values / mean_val
            obj_arr += obj_weights[i] * pred_df[obj_perf_colns[i]].values / mean_val
        pred_df_vld = pd.DataFrame(np.c_[test_df_vld[conf_colns].values, obj_vld_arr], columns=conf_colns + ['obj'])
        pred_df = pd.DataFrame(np.c_[test_df[conf_colns].values, obj_arr], columns=conf_colns + ['obj'])
    
    top_smpl = tool.gen_top_df(pred_df, perf_coln, topn)
    if (eval_flag != 0):
        recall, precision = tool.eval_fail(pred_df_chk, test_df)
        err_prcntl_df = tool.eval_err(pred_df_vld, test_df_vld, perf_coln)
        tool.eval_top_match(pred_df_vld, test_df_vld, conf_colns, perf_coln)
        top_rs_df = tool.eval_top_match(pred_df, test_df, conf_colns, perf_coln)
        return top_smpl, err_prcntl_df, top_rs_df
    else:
        return top_smpl

def whl_pred_top_eval(train_df, test_df, conf_colns, perf_coln, topn=1, eval_flag=1, fn=''):
    mdl_chk, mdl = train_mdl_chk(train_df, conf_colns, perf_coln)
    
    test_X_chk = test_df[conf_colns].values
    pred_y_chk = mdl_chk.predict(test_X_chk)
    for i in range(test_df.shape[0]):
        if (pred_y_chk[i] > 0.0005):
            pred_y_chk[i] = 1.0
        else:
            pred_y_chk[i] = 0.0
    pred_df_chk = pd.DataFrame(np.c_[test_X_chk, pred_y_chk], columns=conf_colns + ['runnable'])
        
    test_df_vld = tool.get_vld_df(test_df)
    test_X_vld = test_df_vld[conf_colns].values
    pred_y_vld = mdl.predict(test_X_vld)
    pred_df_vld = pd.DataFrame(np.c_[test_X_vld, pred_y_vld], columns=conf_colns + [perf_coln])
    
    pred_df = pred_df_chk[(pred_df_chk.runnable == 1.0)]
    test_X = pred_df[conf_colns].values
    pred_y = mdl.predict(test_X)
    pred_df = pd.DataFrame(np.c_[test_X, pred_y], columns=conf_colns + [perf_coln])
    pred_df_invld = pred_df_chk[(pred_df_chk.runnable == 0.0)]
    pred_y = pred_df_invld['runnable'].values + np.ones(pred_df_invld.shape[0]) * float('inf')
    pred_df_invld = pd.DataFrame(np.c_[pred_df_invld[conf_colns].values, pred_y], columns=conf_colns + [perf_coln])
    pred_df = pred_df.append(pred_df_invld)
    
    top_smpl = tool.gen_top_df(pred_df, perf_coln, topn)
    if (eval_flag != 0):
        recall, precision = tool.eval_fail(pred_df_chk, test_df)
        err_prcntl_df = tool.eval_err(pred_df_vld, test_df_vld, perf_coln)
        tool.eval_top_match(pred_df_vld, test_df_vld, conf_colns, perf_coln)
        top_rs_df = tool.eval_top_match(pred_df, test_df, conf_colns, perf_coln)
        perf_df = pd.DataFrame(np.c_[test_df.sort_values(conf_colns)[perf_coln].values, \
                                     pred_df.sort_values(conf_colns)[perf_coln].values], \
                               columns=['real_'+perf_coln, 'pred_'+perf_coln])
        if (fn != ''):
            df2csv(perf_df, fn)
        return top_smpl, err_prcntl_df, top_rs_df
    else:
        return top_smpl
    
def whl_in_pred_top_eval(train_df, test_df, inparams, conf_in_colns, conf_colns, perf_coln, topn=1, eval_flag=1):
    mdl_chk, mdl = train_mdl_chk(train_df, conf_in_colns, perf_coln)
    
    test_num_chk = test_df.shape[0]
    in_X_chk = np.asarray([np.asarray(inparams) for i in range(test_num_chk)])
    test_X_chk = np.concatenate((in_X_chk, test_df[conf_colns].values), axis=1)
    pred_y_chk = mdl_chk.predict(test_X_chk)
    for i in range(test_num_chk):
        if (pred_y_chk[i] > 0.0005):
            pred_y_chk[i] = 1.0
        else:
            pred_y_chk[i] = 0.0
    pred_df_chk = pd.DataFrame(np.c_[test_df[conf_colns].values, pred_y_chk], columns=conf_colns + ['runnable'])
    
    test_df_vld = tool.get_vld_df(test_df)
    test_num_vld = test_df_vld.shape[0]
    in_X_vld = np.asarray([np.asarray(inparams) for i in range(test_num_vld)])
    test_X_vld = np.concatenate((in_X_vld, test_df_vld[conf_colns].values), axis=1)
    pred_y_vld = mdl.predict(test_X_vld)
    pred_df_vld = pd.DataFrame(np.c_[test_df_vld[conf_colns].values, pred_y_vld], columns=conf_colns + [perf_coln])
    
    pred_df = pred_df_chk[(pred_df_chk.runnable == 1.0)]
    test_num = pred_df.shape[0]
    in_X = np.asarray([np.asarray(inparams) for i in range(test_num)])
    test_X = np.concatenate((in_X, pred_df[conf_colns].values), axis=1)
    pred_y = mdl.predict(test_X)
    pred_df = pd.DataFrame(np.c_[pred_df[conf_colns].values, pred_y], columns=conf_colns + [perf_coln])
    pred_df_invld = pred_df_chk[(pred_df_chk.runnable == 0.0)]
    pred_y = pred_df_invld['runnable'].values + np.ones(pred_df_invld.shape[0]) * float('inf')
    pred_df_invld = pd.DataFrame(np.c_[pred_df_invld[conf_colns].values, pred_y], columns=conf_colns + [perf_coln])
    pred_df = pred_df.append(pred_df_invld)
    
    top_smpl = tool.gen_top_df(pred_df, perf_coln, topn)
    if (eval_flag != 0):
        recall, precision = tool.eval_fail(pred_df_chk, test_df)
        err_prcntl_df = tool.eval_err(pred_df_vld, test_df_vld, perf_coln)
        tool.eval_top_match(pred_df_vld, test_df_vld, conf_colns, perf_coln)
        top_rs_df = tool.eval_top_match(pred_df, test_df, conf_colns, perf_coln)
        return top_smpl, err_prcntl_df, top_rs_df
    else:
        return top_smpl


