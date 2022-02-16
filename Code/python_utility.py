# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

from sklearn.cluster import estimate_bandwidth
from sklearn import metrics

def estimate_bandwidth_meanshift(features, perc, quantile=0.5):
    print('Start estimating bandwidth -------------------------------------')
    
    bandwidth = estimate_bandwidth(features, quantile=quantile, n_samples = int(features.shape[0]*perc/100))
    
    print('End estimating bandwidth ---------------------------------------')
    
    return bandwidth

def getNMI(prediction, gt):
    return metrics.normalized_mutual_info_score(gt, prediction)

def getARI(prediction, gt):
    return metrics.adjusted_rand_score(gt, prediction)