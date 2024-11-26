#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Get started on CEBRA
Created on Wed Nov 13 09:20:43 2024

@author: mirko.articus
"""

import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import datetime
from time import time
import numpy as np
import argparse
import os

# directories
input_dir = '/zi-flstorage/data/Mirko/share/CEBRA_test_data'

def runCEBRA(inputfile, sessions):   
    # parameters
    max_iterations = 10000    
    inputfilename = os.path.splitext(os.path.basename(inputfile))[0]
    
    # load data
    neural = cebra.load_data(inputfile,key=''.join(['neural_', str(sessions[0])]))
    discrete_context = cebra.load_data(inputfile,key=''.join(['discrete_', str(sessions[0])]))
    continuous_context = cebra.load_data(inputfile,key=''.join(['spectral_lowlipY_', str(sessions[0])]))
        
    # prepare models
    cebra_shuffle_model = CEBRA(
        model_architecture = "offset10-model",
        batch_size = 4096, 
        temperature_mode="auto",
        learning_rate = 0.001,
        max_iterations = max_iterations,
        time_offsets = 10,
        output_dimension = 8,
        conditional='time_delta',
        device = "cuda_if_available",
        verbose = True
    )
    
    cebra_time_model = CEBRA(
        model_architecture = "offset10-model",
        batch_size = 4096, 
        temperature_mode="auto",
        learning_rate = 0.001,
        max_iterations = max_iterations,
        time_offsets = 10,
        output_dimension = 8,
        conditional='time',
        device = "cuda_if_available",
        verbose = True
    )
    
    cebra_discrete_model = CEBRA(
        model_architecture = "offset10-model",
        batch_size = 4096, 
        temperature_mode="auto",
        learning_rate = 0.001,
        max_iterations = max_iterations,
        time_offsets = 10,
        output_dimension = 8,
        conditional='time_delta',
        device = "cuda_if_available",
        verbose = True
    )

    cebra_behavior_model = CEBRA(
        model_architecture = "offset10-model",
        batch_size = 4096, 
        temperature_mode="auto",
        learning_rate = 0.001,
        max_iterations = max_iterations,
        time_offsets = 10,
        output_dimension = 8,
        conditional='time_delta',
        device = "cuda_if_available",
        verbose = True      
    )

    cebra_justbehavior_model = CEBRA(
        model_architecture = "offset10-model",
        batch_size = 4096, 
        temperature_mode="auto",
        learning_rate = 0.001,
        max_iterations = max_iterations,
        time_offsets = 10,
        output_dimension = 8,
        conditional='time_delta',
        device = "cuda_if_available",
        verbose = True      
    )
    
    # shuffle behavior
    discrete_context_shuffle = np.random.permutation(discrete_context)

    # fit & safe models
    cebra_shuffle_model.fit(neural,discrete_context_shuffle)
    cebra_shuffle_model_name = ''.join([inputfilename,'_shuffle.pt'])
    cebra_shuffle_model.save(cebra_shuffle_model_name)
    
    cebra_time_model.fit(neural)
    cebra_time_model_name = ''.join([inputfilename,'_time.pt'])
    cebra_time_model.save(cebra_time_model_name)

    cebra_discrete_model.fit(neural,discrete_context)
    cebra_discrete_model_name = ''.join([inputfilename,'_discrete.pt'])
    cebra_discrete_model.save(cebra_discrete_model_name)

    cebra_behavior_model.fit(neural,discrete_context,continuous_context)
    cebra_behavior_model_name = ''.join([inputfilename,'_behavior.pt'])
    cebra_behavior_model.save(cebra_behavior_model_name)

    cebra_justbehavior_model.fit(continuous_context,discrete_context)
    cebra_justbehavior_model_name = ''.join([inputfilename,'_justbehavior.pt'])
    cebra_justbehavior_model.save(cebra_justbehavior_model_name)
        
    #transform
    cebra_shuffle_model = cebra.CEBRA.load(cebra_shuffle_model_name)
    cebra_shuffle = cebra_shuffle_model.transform(neural)
    
    cebra_time_model = cebra.CEBRA.load(cebra_time_model_name)
    cebra_time = cebra_time_model.transform(neural)    

    cebra_discrete_model = cebra.CEBRA.load(cebra_discrete_model_name)
    cebra_discrete = cebra_discrete_model.transform(neural)

    cebra_behavior_model = cebra.CEBRA.load(cebra_behavior_model_name)
    cebra_behavior = cebra_behavior_model.transform(neural)

    cebra_justbehavior_model = cebra.CEBRA.load(cebra_justbehavior_model_name)
    cebra_justbehavior = cebra_justbehavior_model.transform(continuous_context)
    
    # plotting   
    cebra_cmap = get_cebra_cmap()
    '''
    # todo:
    # - change scatter point size, make smaller
    # - make 2 plots showing up to latent 6 
    # - make PCA and GPFA plot as comparison
    
    f=plt.figure(figsize=(2,2))
<Figure size 200x200 with 0 Axes>
>>> ax=plt.subplot(111,projection='3d')
>>> scatter = ax.scatter(cebra_behavior[:, 0], cebra_behavior[:, 1], cebra_behavior[:, 2], c=discrete_context, cmap=cebra_cmap)
>>> cbar = fig.colorbar(scatter)
cbar = f.colorbar(scatter)
>>> labels = ['ITI','A','B','aC','bC','aD','bD','cR','dR','cN','dN']
cbar.set_ticks(range(0,11)) # == 0:10 in matlab
>>> cbar.set_ticklabels(labels)
    '''
    
    
    fig = plt.figure(figsize=(24,8))
    
    ax1 = plt.subplot(141, projection='3d')
    ax2 = plt.subplot(142, projection='3d')
    ax3 = plt.subplot(143, projection='3d')
    ax4 = plt.subplot(144, projection='3d')
        
    ax1=cebra.plot_embedding(ax=ax1, embedding=cebra_shuffle, embedding_labels=discrete_context_shuffle[:,0], title='Shuffle', cmap=cebra_cmap)
    ax2=cebra.plot_embedding(ax=ax2, embedding=cebra_time, embedding_labels=discrete_context[:,0], title='Time', cmap=cebra_cmap)
    ax3=cebra.plot_embedding(ax=ax3, embedding=cebra_discrete, embedding_labels=discrete_context[:,0], title='States', cmap=cebra_cmap)    
    ax4=cebra.plot_embedding(ax=ax4, embedding=cebra_justbehavior, embedding_labels=discrete_context[:,0], title='States and just Lip', cmap=cebra_cmap)
    
    # plt.close()
    plt.show()    

def get_cebra_cmap():
    discrete_colors = np.array(
            [[.5, .5, .5, 0], # ITI
            [1, 0, 0, 1], # A
            [0.0039, 0.1765, 0.4314, 1], # B
            [1, 0, 1, 1], # aC
            [0.5882, 0.0118, .5882, 1], # bC
            [0.0745, 0.6235, 1, 1], # aD
            [0, 0, 1, 1], # bD
            [0.9882, 0.7922, 0, 1], # cR
            [0.9804, 0.3843, 0.1255, 1], # dR
            [0.3373, 0.7216, 0.0667, 1], # cN
            [0.0039, 0.3216, 0.0863, 1]]) # dN
    cebra_cmap = ListedColormap(discrete_colors)
    return cebra_cmap

if __name__ == '__main__':        
    # check input args
    parser = argparse.ArgumentParser(description="Check for Inputs")
    parser.add_argument("-i","--inputfile",type=str, help="inputfile")
    parser.add_argument("-o","--outputdir",type=str, help="outputdirectory")
    parser.add_argument("-s","--sessions",nargs='*',type=int , help="sessions")
    parser.add_argument("-g","--gpu",type=int,default=0,help="GPU index to use for computation (default: 0)")    
    args = parser.parse_args()
    
    os.chdir(args.outputdir)
    
    # Set the GPU device before(!) importing CEBRA
    os.environ["CUDA_VISIBLE_DEVICES"]=str(args.gpu)
    print(f"Using GPU {args.gpu} for computation")    
    import cebra
    from cebra import CEBRA
    
    print(datetime.datetime.now())
    start_time = time()
    runCEBRA(args.inputfile,args.sessions)        
    
    end_time = time()
    elapsed_time = end_time - start_time    
    formatted_time = str(datetime.timedelta(seconds=int(elapsed_time)))
    print(f"Time elapsed: {formatted_time}")

