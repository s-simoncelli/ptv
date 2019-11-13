function h = plotErrors(this)
%PLOTERRORS Plots histograms showeing the reprojection and rectification
%error for the calibration.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    h = figure;
    subplot(211);
    
    ax = showReprojectionErrors(this.stereoParams);
    set(ax, 'XTick', 1:this.totalFrames);
    set(ax, 'XTickLabel', this.fileNames);
    xlabel(sprintf('Image Pairs (%d)', this.totalFrames));
    xtickangle(gca, 90);
    
    %% Epiopolar errors
    % Mean error per stereo image pair
    G = repmat(1:this.totalFrames, prod(this.boardSize-1), 1); % use inner corners
    G = G(:);
    e1 = accumarray(G, this.rectificationError.left, [this.totalFrames 1], @mean);
    e2 = accumarray(G, this.rectificationError.right, [this.totalFrames 1], @mean);

    subplot(212);
    A = cellfun(@(i) strsplit(i, '_'), this.fileNames, 'UniformOutput', false);
    str = cellfun(@(i) i{1}, A, 'UniformOutput', false);
    c = categorical(1:this.totalFrames, 1:this.totalFrames, str); % force natural sorting
%     c = categorical(e1, e1, this.fileNames); 
    bar(c, [e1 e2]);
    line(xlim(), [1 1]*this.rectificationError.mean, 'LineStyle','--', 'Color','r')
    legend({'Camera 1', 'Camera 2', sprintf('Average Epipolar Error=%.2f pixels', this.rectificationError.mean)})
    xlabel(sprintf('Image Pairs (%d)', this.totalFrames));
    ylabel('Mean Epipolar Error');
    title('Mean Epipolar Error per Image');
    xtickangle(gca, 90);
end

