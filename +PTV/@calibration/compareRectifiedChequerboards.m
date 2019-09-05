function [] = compareRectifiedChequerboards(this)
% COMPARERECTIFIEDCHEQUERBOARDS Compare rectified frames containing the 
% chequerboards used in the calibration.
% Chequer edges should be row-aligned according to epipolar geometry.
% If this is not the case, the calibration is not correct.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    totalFrames = length(this.imagesUsed);

    for i=1:totalFrames
        fprintf('>> Frame %d/%d (CTRL+C to stop)\n', i, totalFrames);

        leftFrame = imread(this.imagesLeftAll{i});
        rightFrame = imread(this.imagesRightAll{i});

        [leftFrameRect, rightFrameRect] = ...
            rectifyStereoImages(leftFrame, rightFrame, this.stereoParams, 'OutputView', 'valid');

        figure;
        imshow(stereoAnaglyph(leftFrameRect, rightFrameRect));

        hold on;
        [l, h, d] = size(leftFrame);
        for h_i=1:50:h
            plot(get(gca, 'XLim'), h_i*[1 1], 'g-', 'LineWidth', 1);
        end

        pause;

        close(gcf);
    end
end