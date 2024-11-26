function convertSpikesToHDF5(spikeData, outputFile)
% convertSpikesToHDF5 Converts cell array of spike timestamps to HDF5 format
%
% Parameters:
%   spikeData - Cell array where each cell contains spike timestamps for one unit
%   outputFile - String, path to output HDF5 file
%
% Example:
%   spikes = {[1.1 1.2 1.3], [2.1 2.2], [3.1 3.2 3.3 3.4]}; % Example data
%   convertSpikesToHDF5(spikes, 'spikes.h5');

    % Input validation
    if ~iscell(spikeData)
        error('Input spikeData must be a cell array');
    end
    
    % Create or open HDF5 file
    if exist(outputFile, 'file')
        delete(outputFile);
    end
    
    % Create the HDF5 file and add metadata
    n_units = length(spikeData);
    h5create(outputFile, '/spikes/metadata/n_units', 1);
    h5write(outputFile, '/spikes/metadata/n_units', n_units);
    
    % Store each unit's spike times
    for i = 1:n_units
        % Get current unit's spike times
        unit_spikes = spikeData{i};
        
        % Convert to column vector if necessary
        if size(unit_spikes, 1) == 1
            unit_spikes = unit_spikes';
        end
        
        % Create dataset path for this unit
        unit_path = sprintf('/spikes/unit_%d/timestamps', i-1); % 0-based indexing
        
        % Create dataset with compression
        h5create(outputFile, unit_path, size(unit_spikes), ...
            'Datatype', 'double', ...
            'ChunkSize', min(size(unit_spikes), [1024 1]), ... % Adjust chunk size as needed
            'Deflate', 9); % Maximum compression
        
        % Write spike timestamps
        h5write(outputFile, unit_path, unit_spikes);
        
        % Add unit-specific metadata
        metadata_path = sprintf('/spikes/unit_%d/metadata/', i-1);
        
        % Number of spikes
        h5create(outputFile, [metadata_path 'n_spikes'], 1);
        h5write(outputFile, [metadata_path 'n_spikes'], length(unit_spikes));
        
        % Time range
        if ~isempty(unit_spikes)
            h5create(outputFile, [metadata_path 'start_time'], 1);
            h5write(outputFile, [metadata_path 'start_time'], min(unit_spikes));
            
            h5create(outputFile, [metadata_path 'end_time'], 1);
            h5write(outputFile, [metadata_path 'end_time'], max(unit_spikes));
        end
    end
end

function spikes = readSpikesFromHDF5(inputFile, unitIndices)
% readSpikesFromHDF5 Reads spike data from HDF5 file
%
% Parameters:
%   inputFile - String, path to input HDF5 file
%   unitIndices - Optional array of unit indices to load (0-based)
%
% Returns:
%   spikes - Cell array containing spike timestamps for requested units
%
% Example:
%   % Read all units
%   allSpikes = readSpikesFromHDF5('spikes.h5');
%   % Read specific units (0-based indices)
%   someSpikes = readSpikesFromHDF5('spikes.h5', [0 2]);

    if ~exist('unitIndices', 'var')
        % Get total number of units
        n_units = h5read(inputFile, '/spikes/metadata/n_units');
        unitIndices = 0:(n_units-1);
    end
    
    % Initialize output cell array
    spikes = cell(length(unitIndices), 1);
    
    % Read each requested unit
    for i = 1:length(unitIndices)
        unit_idx = unitIndices(i);
        unit_path = sprintf('/spikes/unit_%d/timestamps', unit_idx);
        
        try
            spikes{i} = h5read(inputFile, unit_path);
        catch ME
            warning('Could not read unit %d: %s', unit_idx, ME.message);
            spikes{i} = [];
        end
    end
end