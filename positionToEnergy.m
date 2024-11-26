% Main analysis function
function movement_data = positionToEnergy(x, y, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'x', @isnumeric);
    addRequired(p, 'y', @isnumeric);
    addParameter(p, 'dt', 1/30, @isnumeric);  % default 30 fps
    addParameter(p, 'smoothing', true, @islogical);
    parse(p, x, y, varargin{:});
    
    dt = p.Results.dt;
    doSmoothing = p.Results.smoothing;
    
    % Ensure column vectors
    x = x(:);
    y = y(:);
    
    % Optionally smooth position data
    if doSmoothing
        windowSize = 15;  % must be odd
        polyOrder = 3;
        x = sgolayfilt(x, polyOrder, windowSize);
        y = sgolayfilt(y, polyOrder, windowSize);
    end
    
    % Calculate velocities using gradient
    vx = gradient(x) / dt;
    vy = gradient(y) / dt;
    
%     % Diff instead of gradient       
%     vx = diff(x([1 1:end])) / dt;
%     vy = diff(y([1 1:end])) / dt;
    
    % Optional velocity smoothing
    if doSmoothing
        vx = sgolayfilt(vx, polyOrder, windowSize);
        vy = sgolayfilt(vy, polyOrder, windowSize);
    end
    
    % Calculate speed and movement energy
    speed = sqrt(vx.^2 + vy.^2);
    movement_energy = 0.5 * speed.^2;  % mass set to 1
    
    % Calculate displacement and cumulative distance
    displacement = sqrt(diff(x).^2 + diff(y).^2);
    cumulative_distance = [0; cumsum(displacement)];
    
    % Detect periods of high movement
    speed_threshold = mean(speed) + 2 * std(speed);
    high_movement = speed > speed_threshold;
    
    % Store results in a structure
    movement_data = struct();
    movement_data.movement_energy = movement_energy;
    movement_data.speed = speed;
    movement_data.velocity_x = vx;
    movement_data.velocity_y = vy;
    movement_data.displacement = displacement;
    movement_data.cumulative_distance = cumulative_distance;
    movement_data.high_movement = high_movement;
end

% Function to analyze behavioral periods
function movement_bouts = analyzeBehavioralPeriods(movement_data, varargin)
    % Parse input parameters
    p = inputParser;
    addRequired(p, 'movement_data', @isstruct);
    addParameter(p, 'fps', 30, @isnumeric);
    addParameter(p, 'min_period_length', 0.1, @isnumeric);
    parse(p, movement_data, varargin{:});
    
    fps = p.Results.fps;
    min_period_length = p.Results.min_period_length;
    
    % Convert minimum period length to frames
    min_frames = round(min_period_length * fps);
    high_movement = movement_data.high_movement;
    
    % Find transitions between movement states
    movement_changes = diff([0; high_movement; 0]);
    movement_start = find(movement_changes == 1);
    movement_end = find(movement_changes == -1) - 1;
    
    % Calculate durations
    movement_durations = movement_end - movement_start + 1;
    
    % Filter out short periods
    valid_periods = movement_durations >= min_frames;
    movement_start = movement_start(valid_periods);
    movement_end = movement_end(valid_periods);
    movement_durations = movement_durations(valid_periods);
    
    % Store results in structure
    movement_bouts = struct();
    movement_bouts.start_frames = movement_start;
    movement_bouts.end_frames = movement_end;
    movement_bouts.durations = movement_durations / fps;  % convert to seconds
end

% Function to plot movement analysis
function plotMovementAnalysis(time, movement_data, movement_bouts)
    % Create figure with two subplots
    figure('Position', [100 100 1000 800]);
    
    % Plot speed and movement energy
    subplot(2,1,1);
    plot(time, movement_data.speed, 'DisplayName', 'Speed');
    hold on;
    plot(time, sqrt(movement_data.movement_energy), ...
         'DisplayName', '?Movement Energy', 'Alpha', 0.7);
    
    % Add movement bout highlights if provided
    if nargin > 2 && ~isempty(movement_bouts)
        for i = 1:length(movement_bouts.start_frames)
            x_start = time(movement_bouts.start_frames(i));
            x_end = time(movement_bouts.end_frames(i));
            y_lim = ylim;
            patch([x_start x_end x_end x_start], ...
                  [y_lim(1) y_lim(1) y_lim(2) y_lim(2)], ...
                  'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end
    end
    
    xlabel('Time (s)');
    ylabel('Movement (units/s)');
    legend('Location', 'best');
    grid on;
    
    % Plot velocity trajectory
    subplot(2,1,2);
    plot(movement_data.velocity_x, movement_data.velocity_y, ...
         'b-', 'Alpha', 0.5);
    xlabel('X velocity');
    ylabel('Y velocity');
    axis equal;
    grid on;
end

% Example usage
function example_usage()
    % Generate sample data
    t = linspace(0, 10, 300)';
    radius = 1.0;
    omega = 2;
    x = radius * cos(omega * t);
    y = radius * sin(omega * t) + 2;
    
    % Analyze movement
    movement_data = positionToEnergy(x, y, 'dt', t(2)-t(1));
    
    % Analyze behavioral periods
    movement_bouts = analyzeBehavioralPeriods(movement_data, ...
                                            'fps', 30, ...
                                            'min_period_length', 0.1);
    
    % Plot results
    plotMovementAnalysis(t, movement_data, movement_bouts);
end