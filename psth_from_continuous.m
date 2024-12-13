%% pass partout function to plot psth for PMC3 data, regardless of input data (iFR, pupil, behavior)
%% TODO
% - zscore
% - error propagation
% - implement multi session
% ...
function fig = psth_from_continuous(continuous_data,timestamps,trialmatrix,sample_rate,varargin)
p = inputParser;
addRequired(p, 'continuous_data', @isnumeric);
addRequired(p, 'timestamps', @isnumeric);
addRequired(p, 'trialmatrix', @isnumeric);
addRequired(p, 'sample_rate', @isnumeric); 
addParameter(p, 'events',[], @isstruct); 
addParameter(p, 'norm', 'none', @ischar);
addParameter(p, 'title','' , @ischar);

parse(p, continuous_data, timestamps, trialmatrix, sample_rate, varargin{:});
events = p.Results.events;
norm_method = p.Results.norm;
Title = p.Results.title;
%%

if isempty(timestamps)||isempty(trialmatrix)   
   assert(isstruct(events))
   [timestamps,trialmatrix] = get_timestamps_and_trialmatrix(events);
end

trialmatrix(trialmatrix ==10) = 6;

% figure stuff
figs = [15 5].*.75;
fs = 6; %fontsize
ps = [figs(1)*.225 figs(2)*.675;...
    figs(1)*.225 figs(2)*.675;...
    figs(1)*.45 figs(2)*.675];
fig = figure('Position',[1 1 figs]);

base_window = [-2.2 -.2];
epoch_windows = [-1 2; -1 2; -1 6];
stimBars = {{0 1.2},{0 1.2},{0}};
patchColor = [.7 .7 .7;.9 0 0];
timevec = {epoch_windows(1,1):1/sample_rate:epoch_windows(1,2),...
    epoch_windows(2,1):1/sample_rate:epoch_windows(2,2),...
    epoch_windows(3,1):1/sample_rate:epoch_windows(3,2)};
epocStrs ={'CS1','CS2','US'};
states = [1 2 2]; 


%% loop epochs
for e = 1:3
    psax(e) = axes('Position',[1+(e-1)*.225+ps(1,1)*(e -1) 1 ps(e,:)]);
    hold on
    % colors and trial codes
    [colorlabel{e},legstr{e},code] = get_colegcode(epocStrs{e},states(e)); %,'manipulation',Manip{mx},'paradigm',para);
    
    
    for s = 1:size(code,1)
        % trial idcs
        trx = find(PSTHindex(trialmatrix,code(s,:),[]));%,Manip{mx}));        
        data_matrix = zeros(numel(trx), numel(timevec{e}));        
        
        for i = 1:numel(trx)
            start_idx = round((timestamps(trx(i),e) + epoch_windows(e,1)) * sample_rate);
            end_idx = start_idx + numel(timevec{e}) - 1;                                   
            
            switch norm_method
                case 'base_division'
                    base_bins = round(base_window + timestamps(trx(i),1)) * sample_rate;
                    base_median = median(continuous_data(base_bins),'omitnan');
                    data_matrix(i, :) = continuous_data(start_idx:end_idx)/base_median;
                case 'base_subtraction'
                    base_bins = round(base_window + timestamps(trx(i),1)) * sample_rate;
                    base_median = median(continuous_data(base_bins),'omitnan');
                    data_matrix(i, :) = continuous_data(start_idx:end_idx)-base_median;
                case 'none'
                    data_matrix(i, :) = continuous_data(start_idx:end_idx);
                otherwise
                        warning('Unknown norm method!')
                        keyboard
            end
        end
        
        
        M = mean(data_matrix,'omitnan');         
        SE = std(data_matrix,0,'omitnan')/sqrt(size(data_matrix,1));
%         % single trial
%         plot(repmat(timevec{e},size(data_matrix,1),1)',data_matrix','.','MarkerSize',2.5,'Color',colorlabel{e}{s});
        % trial type mean
        boundedline(timevec{e},M,SE*1.96,'cmap',colorlabel{e}{s},'alpha');        
        
    end
    title(epocStrs{e})
end
 linkaxes(psax,'y')

for s = 1:numel(stimBars)
    set(fig,'CurrentAxes',psax(s))
    yLimStim = ylim;
    if s==numel(stimBars)
        patch([stimBars{s}{1} stimBars{s}{1}+.1 stimBars{s}{1}+.1 stimBars{s}{1}],[yLimStim(2)-diff(yLimStim)*.05 yLimStim(2)-diff(yLimStim)*.05 yLimStim(2) yLimStim(2)],patchColor(1,:),'EdgeColor','none','FaceAlpha',1)
        xline(stimBars{s}{1})        
    else
        patch([stimBars{s}{[1 2]} stimBars{s}{[2 1]}],[yLimStim(2)-diff(yLimStim)*.05 yLimStim(2)-diff(yLimStim)*.05 yLimStim(2) yLimStim(2)],patchColor(1,:),'EdgeColor','none','FaceAlpha',1)
        xline(stimBars{s}{1})
        xline(stimBars{s}{2})
    end
end
 
if ~isempty(Title)
    fig = add_title(fig,Title);
end
end

%%subfunctions
function [timestamps,trial_matrix] = get_timestamps_and_trialmatrix(events)
% data has to be aligned to timestamps already!
    cs1_on = [events.fv_on_odorcue];
    cs1_stim = [events.curr_odorcue_odor_num]; cs1_stim(cs1_stim==10) = 6;
   
    cs2_on = [events.fv_on_rewcue];
    cs2_stim = [events.curr_rewardcue_odor_num];
       
    us_on = [events.reward_time];
    us_stim = [events.drop_or_not];

    trial_matrix = [cs1_stim; cs2_stim; us_stim]';
    timestamps = [cs1_on; cs2_on; us_on]';
end