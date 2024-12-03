%% function to get data ready for CEBRA
% - spike matrix: units*time[ms], binary matrix, 0 = no spike, 1 = spike
% - state matrix: 1D vector 1*time
%   - A=1,B=2,aC=3,bC=4,aD=5,bD=6,cR=7,dR=8,cN=9,dN=10 each 0:2.4 sec from
%   stim onset 
function prepDataForCEBRA(d,sids,uids_all,output_file,varargin)
% settings 
sample_rate = 20;
face_model = 'TD23_Snout_4.3.3';
base_dir = '/zi-flstorage/data/Mirko/TD23/Facemap/output/';

if isempty(sids)
    sids = unique(d.map(uids_all));
end

% preallocate 
spike_data = cell(numel(sids),1);
discrete_context = cell(numel(sids),1);
continuous_energy = cell(numel(sids),1);
continuous_spectral  = cell(numel(sids),1);

%% loop over session
for sx = 1:numel(sids)
    %%  neural as continuous ifr matrix
    if isempty(uids_all)
        uids = find(d.map==sids(sx));
    else
        uids = uids_all(d.map(uids_all)==sids(sx));
    end
    spike_matrix = cell2mat(get_continuous_ifr(d,uids,sample_rate));
    
    %% behavior - lip , nose, paw - as continuous context variable
    % - x,y-position
    [behavior_xy, labels_xy, frameRate] = preprocessBehavior(d,sids(sx),face_model,base_dir);
    
    % - energy
    behavior_energy = NaN(size(behavior_xy)./[2 1]);
    for lx = 2:2:numel(labels_xy)
        tmp = positionToEnergy(behavior_xy(lx-1,:),behavior_xy(lx,:), 'dt', 1/frameRate);
        behavior_energy(lx/2,:) = tmp.movement_energy;
    end
    labels_energy = "energy_" + extractBefore(labels_xy(2:2:end), strlength(labels_xy(2:2:end)));
    
    % - wavelet transform
    behavior_cwt = positionToSpectral(behavior_xy, frameRate);
    labels_cwt = "spectral_" + labels_xy;
    
    % - wavelet PCA, take first 4 PCs 
    behavior_pc = zeros(numel(labels_xy)/2,4,size(behavior_cwt,3));
%     #zscore
    for lx = 2:2:numel(labels_xy)
        [~,tmp] = pca([squeeze(behavior_cwt(lx-1,:,:))' squeeze(behavior_cwt(lx,:,:))']);
        behavior_pc(lx/2,:,:) = tmp(:,1:4)';
    end
    labels_pc = "pc_" + extractBefore(labels_xy(2:2:end), strlength(labels_xy(2:2:end)));
    %% paradigm states as discrete context variable
    events = d.events{1,sids(sx)};
    
    % A=1,B=2
    cs1_on = round([events.fv_on_odorcue]*1*sample_rate);
    cs1_stim = [events.curr_odorcue_odor_num];
    cs1_code = (cs1_stim==5)*1 + ismember(cs1_stim,[6 10])*2;
    % aC=3,bC=4,aD=5,bD=6
    cs2_on = round([events.fv_on_rewcue]*1*sample_rate);
    cs2_stim = [events.curr_rewardcue_odor_num];
    cs2_code = (cs1_stim==5 & cs2_stim==7)*3 + (ismember(cs1_stim,[6 10]) & cs2_stim==7)*4 ...
            + (cs1_stim==5 & cs2_stim==8)*5 + (ismember(cs1_stim,[6 10]) & cs2_stim==8)*6;
    % cR=7,dR=8,cN=9,dN=10 
    us_on = round([events.reward_time]*1*sample_rate);
    us_stim = [events.drop_or_not];
    us_code = (cs2_stim==7 & us_stim==1)*7 + (cs2_stim==8 & us_stim==1)*8 ...
            + (cs2_stim==7 & us_stim==0)*9 + (cs2_stim==8 & us_stim==0)*10;
    
         
    state_matrix = zeros(1,size(spike_matrix,2));
    
    for tx = 1:numel(events)
        state_matrix(cs1_on(tx):cs1_on(tx)+2.5*sample_rate) = cs1_code(tx);
        state_matrix(cs2_on(tx):cs2_on(tx)+2.5*sample_rate) = cs2_code(tx);
        state_matrix(us_on(tx):us_on(tx)+2.5*sample_rate) = us_code(tx);
    end
   
  
   %% cut data to paradigm
%    ## here
    start_time = events(1).fv_on_odorcue - 5;   
    end_time = events(end).reward_time + 10;   

   % store session data in cell array 
   spike_data{sx} = spike_matrix(:,round(start_time*sample_rate):round(end_time*sample_rate));
   discrete_context{sx} = state_matrix(1,round(start_time*sample_rate):round(end_time*sample_rate));
   continuous_energy{sx} = behavior_energy(:,round(start_time*frameRate):round(end_time*frameRate));
   continuous_spectral{sx} = behavior_cwt(:,:,round(start_time*frameRate):round(end_time*frameRate));

end



% save data to HDF5 file
HDF5forCEBRA(spike_data,discrete_context,sids,output_file,...
    labels_energy,continuous_energy,labels_cwt,continuous_spectral)