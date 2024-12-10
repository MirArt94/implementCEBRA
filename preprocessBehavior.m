function [KpInterp, KpStr, frameRate,d] = preprocessBehavior(d,sid,face_model,base_dir,dewarp_align)

filelist = dir([base_dir face_model '/*.h5']);
filelist = {filelist.name}';
behave_file = [base_dir face_model filesep filelist{~cellfun(@isempty,regexp(filelist, regexptranslate('wildcard',[d.info(sid).animal '*' d.info(sid).date])))}];
if ~exist('dewarp_align','var')
    dewarp_align = 1;
end

% parameters
try 
    frameRate = round(d.info(sid).framerate_snout,2);    
    if frameRate == 20
        pxFrameThresh = 75; 
    elseif frameRate == 30
        pxFrameThresh = 50; 
    elseif isnan(frameRate) || isempty(frameRate)
        error('take standard frameRate')
    else
        warning('Framerate not accepted!')
        keyboard
    end
catch
    if contains(d.path,'TD23')
        dataset = "PMC2"; frameRate = 20; pxFrameThresh = 75; % framewise displacement
    elseif contains(d.path,'PMC3')
        dataset = "PMC3"; frameRate = 30; pxFrameThresh = 50; % framewise displacement
    end
end

pxThresh = 150;

likeThresh = [.7 .7 .7];
consecOutThresh = frameRate;
consecValThresh = frameRate;
ampThresh = 100;

%% load data
tmp = h5read(behave_file,"/Facemap/lowerlip/x");
KpLi = NaN(length(tmp),9);

%lip
KpLi(:,1) = tmp;
KpLiStr(1) = "lowlipX";
KpLi(:,2)= h5read(behave_file,"/Facemap/lowerlip/y");
KpLiStr(2) = "lowlipY";
KpLi(:,3) = h5read(behave_file,"/Facemap/lowerlip/likelihood");
KpLiStr(3) = "lowlipLike";


% paw
KpLi(:,4) = h5read(behave_file,"/Facemap/paw/x");
KpLiStr(4) = "pawX";
KpLi(:,5) = h5read(behave_file,"/Facemap/paw/y");
KpLiStr(5) = "pawY";
KpLi(:,6) = h5read(behave_file,"/Facemap/paw/likelihood");
KpLiStr(6) = "pawLike";

% nose tip
KpLi(:,7) = h5read(behave_file,"/Facemap/nose(tip)/x");
KpLiStr(7) = "nosetipX";
KpLi(:,8) = h5read(behave_file,"/Facemap/nose(tip)/y");
KpLiStr(8) = "nosetipY";
KpLi(:,9) = h5read(behave_file,"/Facemap/nose(tip)/likelihood");
KpLiStr(9) = "nosetipLike";


%% get video intan alignment paras
required_fields = {'LED_on_trigger_snout','LED_off_trigger_snout','LED_on_trigger_intan'};
for rfx = find(~contains(required_fields,fieldnames(d.info)))
   eval(['d.info(1).' required_fields{rfx} ' = [];'])
end

if any(cellfun(@isempty,{d.info(sid).LED_on_trigger_snout d.info(sid).LED_off_trigger_snout d.info(sid).LED_on_trigger_intan}))
    d = IntanSnoutAlign(d,sid);
end

LEDonFrame = d.info(sid).LED_on_trigger_snout;
LEDoffFrame = d.info(sid).LED_off_trigger_snout;
digLEDon = d.info(sid).LED_on_trigger_intan;

%% add start and end median pads for markerposition, likelihood = 1
medPadStart = median(KpLi(LEDonFrame:LEDonFrame+frameRate-1,:),1);
medPadStart(3:3:end) = 1; 
KpLi(1:LEDonFrame-1,:) = repmat(medPadStart,LEDonFrame-1,1);

medPadEnd = median(KpLi(LEDoffFrame-frameRate:LEDoffFrame-1,:),1);
medPadEnd(3:3:end) = 1;
KpLi(LEDoffFrame:end,:) = repmat(medPadEnd,size(KpLi,1)-LEDoffFrame+1,1);

%% remove outlier values
lxx = find(contains(KpLiStr,'Like'));
outlier.like = false(size(KpLi,1),numel(lxx));
for lx = 1:numel(lxx)
    outlier.like(KpLi(:,lxx(lx))<likeThresh(lx),lx) = true;    
end

txx = find(~contains(KpLiStr,'Like'));
coorStr = repmat(['x' 'y'],1,numel(txx)/2);
outlier.x = false(size(KpLi,1),numel(lxx));
outlier.y = false(size(KpLi,1),numel(lxx));
for tx = 1:numel(txx)
    if contains(KpLiStr,'paw'); continue;end
    outlier.(coorStr(tx))(abs(diff([KpLi(1,txx(tx));KpLi(:,txx(tx))]))>pxFrameThresh,ceil(txx(tx)/3)) = true;    
    outlier.(coorStr(tx))(abs(KpLi(:,txx(tx))-median(KpLi(:,txx(tx))))>pxThresh,ceil(txx(tx)/3)) = true;    
end

outlier.all = outlier.like|outlier.x|outlier.y;
consecOutNum = repelem(getConsecOutNum(outlier.all),1,2);
consecOutNum([1:LEDonFrame-1 LEDoffFrame+1:end],:) = 0;

% remove outlier frames
KpClean = KpLi(:,txx);
KpStr = KpLiStr(txx);
for kx=1:size(KpClean,2)
    KpClean(outlier.all(:,ceil(kx/2)),kx) = NaN;
end

%% interpolation of outlier frames
KpInterp = NaN(size(KpClean));
for kx=1:size(KpInterp,2)    
    KpInterp(:,kx) = wavelet_based_impute(KpClean(:,kx), 'db2', 5, 'makima');
end
% remove imputed values in large gaps
KpInterp(consecOutNum>consecOutThresh) = NaN;

% remove signal if only sporadic and short <1 second. Most likely artifacts
consecVals = getConsecOutNum(~isnan(KpInterp));
KpInterp(consecVals<consecValThresh) = NaN;

% remove paw episodes with max amplitude < amp_thresh
pawx = find(contains(KpStr,'paw'),1);
non_nan_idx = find(~isnan(KpInterp(:,pawx)));
non_nan_idx(~ismember(non_nan_idx,LEDonFrame:LEDoffFrame)) = [];
groups = splitvec(non_nan_idx);

for i = 1:length(groups)
    group = groups{i};
    group_values = KpInterp(group,pawx:pawx+1);
    group_range = max(group_values) - min(group_values);
    % If the range is above the threshold, keep the values
    if any(group_range < ampThresh)
        KpInterp(group,pawx:pawx+1) = NaN;
    end
end

% use linear interpolation to fill long gaps
for kx = 1:size(KpInterp,2)
    if any(isnan(KpInterp(:,kx)))
        tmp = KpInterp(:,kx);
        KpInterp(:,kx) = interp1(find(~isnan(tmp)),tmp(~isnan(tmp)),1:numel(tmp),'linear');        
    end
end

if dewarp_align
    %% handle warping (30Hz videos are affected)   
    if isfield(d.info,'timewarp_snout')
        if round(d.info(sid).timewarp_snout,3)~=1
            curr_warpfactor = d.info(sid).timewarp_snout;
            frame_time_warp = 1/(frameRate*curr_warpfactor);
            time_vec = (frame_time_warp:frame_time_warp:size(KpInterp,1)*frame_time_warp);
            
            frame_time_stable = 1/frameRate;
            query_vec = (frame_time_stable:frame_time_stable:size(KpInterp,1)*frame_time_warp);
            LEDonFrame = round(LEDonFrame/curr_warpfactor);
            
            tmp = KpInterp;
            KpInterp = NaN(numel(query_vec),size(KpInterp,2));
            for kx = 1:size(KpInterp,2)
                KpInterp(:,kx) = interp1(time_vec,tmp(:,kx),query_vec,'spline');
            end
        end
    end
    
    %% align video to intan
    video_intan_offset = LEDonFrame - round(digLEDon*frameRate);
    
    if video_intan_offset>0
        KpInterp(1:video_intan_offset,:) = [];
    elseif video_intan_offset<0
        tmp = KpInterp;
        KpInterp = [repmat(tmp(1,:),-video_intan_offset,1);tmp];
    end
end

KpInterp = KpInterp';
end