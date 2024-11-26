#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Get started on CEBRA
Created on Wed Nov 13 09:20:43 2024

@author: mirko.articus
"""
import numpy as np
import cebra
from cebra import CEBRA
import os

# directories
input_dir = '/zi-flstorage/data/Mirko/share/CEBRA_test_data'
filename = 'data_cebra.mat'

# load data
neural_data = cebra.load_data(file(os.path.join(input_dir,filename)))