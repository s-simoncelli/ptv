function [this] = detectParticles(this)
%DETECTPARTICLES detects particles within the frame and returns their
% centroids, areas and bounding boxes.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    % Get binary mask
    this.step.leftMask = this.video.leftDetector.step(this.step.leftFrame);
    this.step.rightMask = this.video.rightDetector.step(this.step.rightFrame);

    % Perform blob analysis to find particles in the left framwe
    [area, centroid, bbox, ax_mj, ax_mn, or, ecc, r2, per] = this.video.leftBlobAnalyser.step(this.step.leftMask);
    id = 1:size(centroid, 1);
    this.step.leftParticles = table(id', area, centroid, bbox, ...
        ax_mj, ax_mn, or, ecc, r2, per);
    this.step.leftParticles.Properties.VariableNames{1} = 'id';
    this.step.leftParticles.area = double(this.step.leftParticles.area);

    % Perform blob analysis to find particles in the right framwe
    [area, centroid, bbox, ax_mj, ax_mn, or, ecc, r2, per] = this.video.rightBlobAnalyser.step(this.step.rightMask);
    id = 1:size(centroid, 1);
    this.step.rightParticles = table(id', area, centroid, bbox, ...
        ax_mj, ax_mn, or, ecc, r2, per);
    this.step.rightParticles.Properties.VariableNames{1} = 'id';
    this.step.rightParticles.area = double(this.step.rightParticles.area);
    
    this.logStatus(sprintf('Step #%d - Left frame found %d particles - Right frame found %d particles', ...
        this.step.counter, height(this.step.leftParticles), ...
        height(this.step.rightParticles)), false);

    maxParticles = this.blobDetectionSettings.maximumCount;
    if(height(this.step.leftParticles) >= maxParticles)
        this.logStatus(sprintf('[!!] Step #%d - Reached the limit for maximum detectable particles in left frame (%d)', ...
            this.step.counter, maxParticles), false);
    end
    
    if(height(this.step.rightParticles) >= maxParticles)
        this.logStatus(sprintf('[!!] Step #%d - Reached the limit for maximum detectable particles in right frame (%d)', ...
            this.step.counter, maxParticles), false);
    end
end
