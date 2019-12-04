function [this] = updateAssignedTracks(this)
%UPDATEASSIGNED updates the assigned tracks with the corresponding
% detection in the frame. A detection is assigned to a track based on the 
% cost function.
% The following track data are altered for the assignments:
%
%   - centroid: the estimated centroid from the Kalman filter is replaced 
%      with the centroid of the detected particle in the left frame
%   - bbox: the estimated bbox from the Kalman filter is replaced 
%      with the centroid of the detected particle in the left frame
%   - age: increased 
%   - totalVisibleCount:  increased
%   - consecutiveInvisibleCount: reset to 0
%   - currentLeftparticleId: updated with the detection.
%   - estimated: set to 0.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    numAssignedTracks = size(this.step.assignments, 1);
    for i=1:numAssignedTracks
        % In assignments the 1st column represents the track index 
        % and the 2nd column represents the detection index
        rowId = this.step.assignments(i, 1);
        detectionIdx = this.step.assignments(i, 2);
        centroid = this.step.leftParticles.centroid(detectionIdx, :);
        
        % Correct the estimate of the object's location using the new detection.
        % The method overwrites the internal state and covariance of the
        % Kalman filter object with the corrected measurement (centroid)
        correct(this.step.tracks.kalmanFilter{rowId}, centroid);
                
        %% Particle data
        % Replace the predicted centroid and bounding box with the detection
        this.step.tracks.centroid(rowId, :) = centroid;
        this.step.tracks.bbox(rowId, :) = this.step.leftParticles.bbox(detectionIdx, :);
        this.step.tracks.area(rowId, :) = this.step.leftParticles.area(detectionIdx, :);
   
        this.step.tracks.ax_mj(rowId, :) = this.step.leftParticles.ax_mj(detectionIdx, :);
        this.step.tracks.ax_mn(rowId, :) = this.step.leftParticles.ax_mn(detectionIdx, :);
        this.step.tracks.or(rowId, :) = this.step.leftParticles.or(detectionIdx, :);
        this.step.tracks.ecc(rowId, :) = this.step.leftParticles.ecc(detectionIdx, :);
        this.step.tracks.r2(rowId, :) = this.step.leftParticles.r2(detectionIdx, :);
        this.step.tracks.per(rowId, :) = this.step.leftParticles.per(detectionIdx, :);
    
        % this is needed to link the track ID to the particle ID currently
        % detected in the frame
        this.step.tracks.currentLeftparticleId(rowId) = ...
            this.step.leftParticles.id(detectionIdx);
        
        % set it to 0 here, because the particle position has been replaced
        % above with the real one
        this.step.tracks.estimated(rowId) = 0;
        
        %% Track data
        % Update track age (in frames).
        this.step.tracks.age(rowId) = this.step.tracks.age(rowId) + 1;

        % Update visibility counter. This is updated only if the track is 
        % assigned
        this.step.tracks.totalVisibleCount(rowId) = ...
            this.step.tracks.totalVisibleCount(rowId) + 1;

        % Reset counter if the track was invisible before
        this.step.tracks.consecutiveInvisibleCount(rowId) = 0;
    end   
    
    timeTaken = toc;
    this.logStatus(sprintf('Step #%d - Updating assigned tracks took %.3f seconds', ...
        this.step.counter, timeTaken), false);
end

