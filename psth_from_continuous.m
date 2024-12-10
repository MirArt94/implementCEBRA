function fig = psth_from_continuous(continuous_data,timestamps,trialmatrix,sample_rate,varargin)
%% pass partout function to plot psth for PMC3 data, regardless of input data (iFR, pupil, behavior)
%% TODO
% - zscore
% - error propagation
% - implement multi session
% ...

if isempty(timestamps)||isempty(trialmatrix)
   evt_idx = find(contains(varargin(1:2:end),'events'))+1;
   assert(~isempty(evt_idx))
   [timestamps,trialmatrix] = get_timestamps_and_trialmatrix(varargin{evt_idx},sample_rate);
end

trialmatrix(trialmatrix ==10) = 6;

% figure stuff
figs = [15 5];
fs = 6; %fontsize
ps = [figs(1)*.225 figs(2)*.675;...
    figs(1)*.225 figs(2)*.675;...
    figs(1)*.45 figs(2)*.675];
fig = figure('Position',[1 1 figs]);


epoch_windows = [-1 2; -1 2; -1 6];
timevec = {epoch_windows(1,1):1/sample_rate:epoch_windows(1,2),...
    epoch_windows(2,1):1/sample_rate:epoch_windows(2,2),...
    epoch_windows(3,1):1/sample_rate:epoch_windows(3,2)};
epocStrs ={'CS1','CS2','US'};
states = [1 2 2]; 

if any(contains(varargin(1:2:end),'title'))
    Title = varargin{find(contains(varargin(1:2:end),'title'))*2};
else
    Title =[];
end

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
            
            data_matrix(i, :) = continuous_data(start_idx:end_idx);
        end
        
        
        M = mean(data_matrix,'omitnan');
        SE = std(data_matrix,0,'omitnan')/sqrt(size(data_matrix,1));
%         % single trial
%         plot(repmat(timevec{e},size(data_matrix,1),1)',data_matrix','.','MarkerSize',2.5,'Color',colorlabel{e}{s});
        % trial type mean
        boundedline(timevec{e},M,SE*1.96,'cmap',colorlabel{e}{s},'alpha');        
        
    end
end
if ~isempty(Title)
    fig = add_title(fig,Title);
end
end

%%subfunctions
function [timestamps,trial_matrix] = get_timestamps_and_trialmatrix(events,sample_rate)
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