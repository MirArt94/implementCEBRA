function cwt_behavior = positionToSpectral(xy_behavior,frameRate)
    %% parameters
    tbw = 10;
    vpo = 10;
    FreqLim = [.5 15];
    max_50wvlt_width = .6; 
    
    [~,Freqs,~,fb] = cwt(ones(size(xy_behavior,2),1),frameRate,'VoicesPerOctave',vpo,...
        'TimeBandwidth',tbw,'FrequencyLimits',FreqLim);
    wvlts = wavelets(fb);
    wvlt_widths = getWaveletWidth(abs(wvlts),frameRate);
    freq_slct = wvlt_widths/2<=max_50wvlt_width;
    cwt_behavior = NaN(size(xy_behavior,1),sum(freq_slct),size(xy_behavior,2));
    for xyx = 1:size(xy_behavior,1)
        tmp = abs(cwt(xy_behavior(xyx,:),'Filterbank',fb));
        cwt_behavior(xyx,:,:) = tmp(freq_slct,:);
    end

end