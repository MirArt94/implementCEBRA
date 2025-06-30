%% reads facemap output, processes coordinates, creates labeled video
function [KpInterp, KpInterpMask, KpStr, frameRate,d] = preprocessBehavior(d,sid,face_model,base_dir,dewarp_align)

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
        ops.pxFrameThresh = 75; 
    elseif frameRate == 30
        ops.pxFrameThresh = 50; 
    elseif isnan(frameRate) || isempty(frameRate)
        error('take standard frameRate')
    else
        warning('Framerate not accepted!')
        keyboard
    end
catch
    if contains(d.path,'TD23')
        frameRate = 20; ops.pxFrameThresh = 75; % framewise displacement
    elseif contains(d.path,'PMC3')
        frameRate = 30; ops.pxFrameThresh = 50; % framewise displacement
    end
end

ops.pxThresh = 150;
ops.likeThresh = [.7 .7 .6];
ops.consecOutThresh = frameRate;
ops.consecValThresh = frameRate;
ops.ampThresh = 100;

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

%% Clean and interpolate data
    [KpInterp, KpInterpMask,KpStr] = facemap_clean_int_data(KpLi, KpLiStr,ops);   

%% handle warping (30Hz videos are affected)   
% interpolate keypoint coordinates for timepoints of integer frameRate 
% relevant when treating continuous data (CEBRA) not if looking at
% trialwise dynamics
if dewarp_align
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