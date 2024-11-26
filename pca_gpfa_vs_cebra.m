%% PCA and GPFA plots from CEBRA input
% tmp = h5info(input_file);
function pca_gpfa_vs_cebra
cebra_cmap = get_cebra_cmap;
neural = h5read(input_file,['/neural_' num2str(sids(sx))])';
discrete  = h5read(input_file,['/discrete_' num2str(sids(sx))])';

% zscore
tmp = neural;
neural = (tmp-mean(tmp,2))/std(tmp,1,2);

% PCA
[coeff,score] = pca(neural);

clf
tiledlayout(1,2)
nexttile
scatter(score(:,1),score(:,2),2,cebra_cmap(discrete+1,:));
nexttile
scatter(score(:,3),score(:,4),2,cebra_cmap(discrete+1,:));

% GPFA
% check paper first!


end

function cebra_cmap = get_cebra_cmap
cebra_cmap = [[.5, .5, .5,]; ... ITI
            [1, 0, 0,]; ... A
            [0.0039, 0.1765, 0.4314,]; ... B
            [1, 0, 1,]; ... aC
            [0.5882, 0.0118, .5882,]; ... bC
            [0.0745, 0.6235, 1,]; ... aD
            [0, 0, 1,]; ... bD
            [0.9882, 0.7922, 0,]; ... cR
            [0.9804, 0.3843, 0.1255,]; ... dR
            [0.3373, 0.7216, 0.0667,]; ... cN
            [0.0039, 0.3216, 0.0863,]]; ... dN
end
