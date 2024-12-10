function HDF5forCEBRA_old(spike_data,spike_data_binned,discrete_context,trial_matrix,timestamps,sids,outputFile,varargin)
% convertSpikesToHDF5 Converts cell array of spike timestamps to HDF5 format
%
% Parameters:
%   spike_data - Cell array where each cell containing a binary matrix (time|neurons)
%   outputFile - String, path to output HDF5 file
%
% Example:
%   spikes = {[1.1 1.2 1.3], [2.1 2.2], [3.1 3.2 3.3 3.4]}; % Example data
%   convertSpikesToHDF5(spikes, 'spikes.h5');
% Input validation
if ~iscell(spike_data)
    error('Input spikeData must be a cell array');
end

if ~isempty(varargin)
    for dsx = 2:2:numel(varargin)
        continuous_context_labels(dsx/2) = varargin(dsx-1);
        continuous_context_data(dsx/2) = varargin(dsx);
    end
end

% delete pre-existing HDF5 file
if exist(outputFile, 'file')
    delet_file = input('outputfile already exist. delete?');       
    if delet_file
        delete(outputFile);
    else
        return
    end
end

%% loop over sessions
for sx = 1:numel(spike_data)
    %% Add spike data to HDF5 file
    
    %     % binary spike matrix
    %     h5create(outputFile, neural_path, [n_units, n_timepoints],...
    %         'Datatype', 'single', ...
    %         'ChunkSize', [min(n_units, 1024) min(n_timepoints, 1024)], ...
    %         'Deflate', 9); % Maximum compression
    %     h5write(outputFile, neural_path, single(spike_data{sx}));
    
    % continuous ifr
    neural_path =  sprintf('/ifr_%d',sids(sx));
    n_units = size(spike_data{sx},1);
    n_timepoints = size(spike_data{sx},2);
    
    h5create(outputFile, neural_path, [n_units, n_timepoints],...
        'Datatype', 'double', ...
        'ChunkSize', [min(n_units, 1024) min(n_timepoints, 1024)], ...
        'Deflate', 9); % Maximum compression
    h5write(outputFile, neural_path,spike_data{sx});
    
    % binned spikecounts
    neural2_path =  sprintf('/spikecount_%d',sids(sx));        
    
    h5create(outputFile, neural2_path, [n_units, n_timepoints],...
        'Datatype', 'single', ...
        'ChunkSize', [min(n_units, 1024) min(n_timepoints, 1024)], ...
        'Deflate', 9); % Maximum compression
    h5write(outputFile, neural2_path,single(spike_data_binned{sx}));
    
    %% Add continuous context data to HDF5 file
    if ~isempty(continuous_context_data)
        for dsx = 1:numel(continuous_context_data)
            curr_dataset = continuous_context_data{dsx}{sx};
            curr_labels = continuous_context_labels{dsx};
            for dx = 1:size(curr_dataset,1)                
                continuous_path =  sprintf(['/' curr_labels{dx} '_%d'],sids(sx));
                curr_data = squeeze(curr_dataset(dx,:,:));
                
                n_variables = size(curr_data,1);
                n_timepoints_cont = size(curr_data,2);
%                 assert(n_timepoints == size(continuous_context_data{sx},2))
                
                h5create(outputFile, continuous_path, [n_variables n_timepoints_cont],...
                    'Datatype', 'double', ...
                    'ChunkSize', [min(n_variables, 1024) min(n_timepoints_cont, 1024)], ...
                    'Deflate', 9); % Maximum compression
                h5write(outputFile, continuous_path, curr_data);
            end
        end
    end
    
    %% Add discrete context data to HDF5 file
    if ~isempty(discrete_context)
        discrete_path =  sprintf('/discrete_%d',sids(sx));
        
        assert(isequal(n_timepoints, max(size(discrete_context{sx},2)), numel(discrete_context{sx})))
        if size(discrete_context{sx},1) ~= 1
            discrete_context{sx} = discrete_context{sx}';
        end
        
        h5create(outputFile, discrete_path, [1 n_timepoints],...
            'Datatype', 'int8', ...
            'ChunkSize', [1 min(n_timepoints, 1024)], ...
            'Deflate', 9); % Maximum compression
        h5write(outputFile, discrete_path, int8(discrete_context{sx}));
    end
    
    %% Add trialmatrix and timestamps
    if ~isempty(trial_matrix)&&~isempty(timestamps)
        tm_path =  sprintf('/trialmatrix_%d',sids(sx));                        
        if size(trial_matrix{sx},1) > size(trial_matrix{sx},2)
            trial_matrix{sx} = trial_matrix{sx}';
        end
        n_trials = size(trial_matrix{sx},2);
        n_states = size(trial_matrix{sx},1);
        
        h5create(outputFile, tm_path, [n_states n_trials],...
            'Datatype', 'int8', ...
            'ChunkSize', [n_states min(n_trials, 1024)], ...
            'Deflate', 9); % Maximum compression
        h5write(outputFile, tm_path, int8(trial_matrix{sx}));
        
        timestamps_path =  sprintf('/timestamps_%d',sids(sx));                        
        if size(timestamps{sx},1) > size(timestamps{sx},2)
            timestamps{sx} = timestamps{sx}';
        end
        n_trials = size(timestamps{sx},2);
        n_states = size(timestamps{sx},1);
        
        h5create(outputFile, timestamps_path, [n_states n_trials],...
            'Datatype', 'double', ...
            'ChunkSize', [n_states min(n_trials, 1024)], ...
            'Deflate', 9); % Maximum compression
        h5write(outputFile, timestamps_path, timestamps{sx});
    end
    
end
end