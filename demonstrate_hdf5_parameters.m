function demonstrate_hdf5_parameters()
    % Create sample data (10000 timepoints x 100 neurons)
    spike_matrix = randi([0 1], 10000, 100);
    
    % Test different chunk sizes and datatypes
    configurations = {
        % filename               datatype    chunksize
        {'spikes_unchunked.h5', 'uint8',    size(spike_matrix)},    % One big chunk
        {'spikes_small.h5',     'uint8',    [100 10]},              % Small chunks
        {'spikes_medium.h5',    'uint8',    [1000 20]},             % Medium chunks
        {'spikes_double.h5',    'double',   [1000 20]},             % Double precision
    };
    
    % Test each configuration
    for i = 1:length(configurations)
        [filename, datatype, chunksize] = configurations{i}{:};
        
        % Save data
        tic;
        save_spikes(spike_matrix, filename, datatype, chunksize);
        save_time = toc;
        
        % Get file size
        file_info = dir(filename);
        file_size = file_info.bytes / 1024; % Size in KB
        
        % Read full dataset
        tic;
        full_read = read_full_spikes(filename);
        full_read_time = toc;
        
        % Read small section
        tic;
        partial_read = read_partial_spikes(filename, [1 1], [100 10]);
        partial_read_time = toc;
        
        % Display results
        fprintf('\nConfiguration: %s\n', filename);
        fprintf('Datatype: %s, Chunk size: [%d %d]\n', datatype, chunksize(1), chunksize(2));
        fprintf('File size: %.2f KB\n', file_size);
        fprintf('Save time: %.4f seconds\n', save_time);
        fprintf('Full read time: %.4f seconds\n', full_read_time);
        fprintf('Partial read time: %.4f seconds\n', partial_read_time);
    end
end

function save_spikes(data, filename, datatype, chunksize)
    if exist(filename, 'file')
        delete(filename);
    end
    
    h5create(filename, '/spikes', size(data), ...
        'Datatype', datatype, ...
        'ChunkSize', chunksize, ...
        'Deflate', 9);
    h5write(filename, '/spikes', data);
end

function data = read_full_spikes(filename)
    data = h5read(filename, '/spikes');
end

function data = read_partial_spikes(filename, start, count)
    data = h5read(filename, '/spikes', start, count);
end