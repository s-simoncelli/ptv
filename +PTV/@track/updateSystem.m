function [this] = updateSystem(this)
%UPDATESYSTEM Updates the system object by adding a new row to the
% provided track ID (trackIdx)
%
%  INPUT:
%    trackIdx    -  The track ID to be updated        [int]
%    data        -  The data to add in the track      [struct]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
     
    h = height(this.step.tracks);
    
    % global indexes
    stepNumber = repmat(this.step.counter, h, 1);
    globalLeftFrame = repmat(this.step.globalLeftFrame, h, 1);
    globalRightFrame = repmat(this.step.globalRightFrame, h, 1);
    t = repmat(this.step.time, h, 1);

    % videos
    leftVideoNum = repmat(this.step.fileIndex.left, h, 1);
    leftFrameId = repmat(this.step.leftFrameId, h, 1);
    rightVideoNum = repmat(this.step.fileIndex.right, h, 1);
    rightFrameId = repmat(this.step.rightFrameId, h, 1);
   
    % track data             
    trackId = this.step.tracks.id;
    age = this.step.tracks.age;
    totalVisibleCount = this.step.tracks.totalVisibleCount;
    totalInvisibleCount = this.step.tracks.totalInvisibleCount;
    consecutiveInvisibleCount = this.step.tracks.consecutiveInvisibleCount;
    estimated = this.step.tracks.estimated;
    lost = this.step.tracks.lost;
   
    % particle data
    x = this.step.tracks.centroid(:, 1);
    y = this.step.tracks.centroid(:, 2);
    disparity = this.step.tracks.disparity;
    area = this.step.tracks.area;
    ax_mj = this.step.tracks.ax_mj;
    ax_mn = this.step.tracks.ax_mn;
    or = this.step.tracks.or;
    ecc = this.step.tracks.ecc;
    r2 = this.step.tracks.r2;
    per = this.step.tracks.per;
    bboxWidth = double(this.step.tracks.bbox(:, 3));
    bboxHeight = double(this.step.tracks.bbox(:, 4));
    
    % data in real world
    X = this.step.tracks.worldCoordinates(:, 1);
    Y = this.step.tracks.worldCoordinates(:, 2);
    Z = this.step.tracks.worldCoordinates(:, 3);
    particleLengthH = this.step.tracks.length(:, 1);
    particleLengthV = this.step.tracks.length(:, 2);

    % new field
    saved = zeros(h, 1);
    
    newRow = table(stepNumber, globalLeftFrame, globalRightFrame, t,...
       leftVideoNum, leftFrameId , rightVideoNum, rightFrameId, ...
       trackId, age, totalVisibleCount, totalInvisibleCount, ...
       consecutiveInvisibleCount, estimated, lost, saved, ...
       x, y, disparity, area, ax_mj, ax_mn, or, ecc, r2, per, bboxWidth, bboxHeight, ...
       X, Y, Z, particleLengthH, particleLengthV);
 
    this.system = [this.system; newRow];
    
    this.logStatus(sprintf('Step #%d - Updating system took %.3f seconds', ...
        this.step.counter, toc), false);
end