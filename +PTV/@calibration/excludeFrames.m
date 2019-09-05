function this = excludeFrames(this)
%EXCLUDEFRAMES Removes frames from the calibration set.

    if(~isempty(this.exclude))
        for e=this.exclude
            I = find(ismember(this.fileNames, sprintf('f%d', e)));
            if(~isempty(I))
                this.imagesLeftAll(I) = [];
                this.imagesRightAll(I) = [];
                this.imagesRightAllPlus(I) = [];
                this.imagesRightAllMinus(I) = [];

                this.imagePointsLeft(:, :, I) = [];
                this.imagePointsRight(:, :, I) = [];
                this.imagePointsRightPlus(:, :, I) = [];
                this.imagePointsRightMinus(:, :, I) = [];
                this.fileNames(I) = [];
            else
                warning('visionToolboxCalibration:cannotRemoveFrame', ...
                    'Frame %d cannot be removed from the calibration set because it does not exist', e);
            end
        end
    end
end

