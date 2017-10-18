# -*- coding: utf-8 -*-
"""
Created on Sun Oct 08 00:08:27 2017

@author: Xichen
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
import pandas as pd

# define Semi-Variance
def semi_var(x):
    mean = np.mean(x)
    ng_ret = np.array(x[x < 0])
    sv = np.sum(np.square(ng_ret - mean)) / len(ng_ret)
    return(sv)

# Bootstrapping function
def boot(x, nboot):
    boot_list = []
    for boot in range(nboot):
        boot_run = np.random.choice(x, size = len(x), replace = True)
        boot_list.append(boot_run)
    return (boot_list)

# Monte-Carlo function
def mc_normal(x, nmc, mean, std):
    mc_list = []
    for mc in range(nmc):
        mc_run = np.random.normal(loc = mean, scale = std, size = len(x))
        mc_list.append(mc_run)
    return (mc_list)

# Define Percantile Method & Normal approximation method for sample confidence interval
def conf_int(x, p):
    mean = np.mean(x)
    std = np.std(x)
    low_p = 0.5 * (1 - p)
    high_p = 1 - 0.5 * (1 - p)
    pct = [np.percentile(x, low_p), np.percentile(x, high_p)]
    norm = [mean + stats.norm.ppf(low_p, 0, 1) * std, mean + stats.norm.ppf(high_p, 0, 1) * std]
    conf = {'percentile':pct, 'normality':norm}
    return (conf)


# Read sp500 return dataset
sp500 = pd.read_csv('sp500yahoo1.csv', index_col = 0, parse_dates = True)
sp500['lag_Adj_Close'] = sp500['Adj Close'].shift(1)
sp500['ret'] = (sp500['Adj Close'] - sp500['lag_Adj_Close']) / sp500['lag_Adj_Close']
sp500 = sp500[1:]

sv = semi_var(sp500['ret'])

print '#sp500 return sv = %10.8f' % sv

# Bootstrap and Monte-carlo sv for sp500
sample = 10000
target = sp500['ret']
boot_list = boot(target, sample)
mc_list = mc_normal(target, sample, np.mean(target), np.std(target))
sv_boot = np.zeros(sample)
sv_mc = np.zeros(sample)
for i in range(sample):
    sv_boot[i] = semi_var(boot_list[i])
    sv_mc[i] = semi_var(mc_list[i])

# Estimate confidence intervals
p = 0.99
conf_boot = conf_int(sv_boot, p)
conf_mc = conf_int(sv_mc, p)
print ('%4.2f confidence interval bootstrapping: \n{}'.format(conf_boot) % p)
print ('%4.2f confidence interval Monte-Carlo: \n{}'.format(conf_mc) % p)


