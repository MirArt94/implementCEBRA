#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Nov 14 12:08:41 2024

@author: mirko.articus
"""
from h5py import File
import h5py

def print_h5_structure(filename):
    with File(filename, 'r') as f:
        print("Keys in file:")
        for key in f.keys():
            print(f"- {key}")
            if isinstance(f[key], h5py.Dataset):
                print(f"  Shape: {f[key].shape}")
                print(f"  Type: {f[key].dtype}")

# Use it on your file
print_h5_structure(filename)