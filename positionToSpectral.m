function cwt_behavior = positionToSpectral(xy_behavior,frameRate)
    %% parameters
    tbw = 10;
    vpo = 10;
    FreqLim = [.5 15];
    
    [~,Freqs,~,fb] = cwt(ones(size(xy_behavior,2),1),frameRate,'VoicesPerOctave',vpo,...
        'TimeBandwidth',tbw,'FrequencyLimits',FreqLim);
    cwt_behavior = NaN(size(xy_behavior,1),numel(Freqs),size(xy_behavior,2));
    for xyx = 1:size(xy_behavior,1)
        cwt_behavior(xyx,:,:) = abs(cwt(xy_behavior(xyx,:),'Filterbank',fb));
    end

end