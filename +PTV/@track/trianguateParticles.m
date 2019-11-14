function [this] = trianguateParticles(this)
%TRIANGULATEPARTICLES estimates the particle coordinates from their disparity. 
% Depth is estimated for particles that have been assigned to a track 
% (this.step.assignments) and for new tracks created when no detections
% were assigned (this.step.unassignedDetections). Tracked already in the
% system but not assigned (this.step.unassignedTracks) are ignored.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    
    % reset all coordinate data for the current tracks
    h = height(this.step.tracks);
    this.step.tracks.disparity = NaN(h, 1);
    this.step.tracks.worldCoordinates = NaN(h, 3);
    
    % try matching the particles in the current assigned tracks. Unassigned
    % tracks have NaN as 'currentLeftparticleIds'.
    rowsToUpdate = ~isnan(this.step.tracks.currentLeftparticleId);
    % particle IDs of the detections.
    trackedParticlesIds = this.step.tracks.currentLeftparticleId(rowsToUpdate);
    
    % each row number corresponds to a particle IDs of the detection.
    trackedParticlesData = this.step.leftParticles(trackedParticlesIds, :);
    
    if(~isempty(trackedParticlesData))
        this.logStatus(sprintf('Step #%d - Found %d tracks with a matched particle for disparity', ...
           this.step.counter, length(trackedParticlesIds)), false);
       
        % the rows in trackedParticlesData, trackIds and data match the same
        % left particle IDs because they have the same sort
        s = this.matchParticlesSettings;
        data = PTV.particleMatching(this.step.leftFrame, this.step.rightFrame, ...
            trackedParticlesData, this.step.rightParticles, ...
            'baseLine', this.baseLine, 'focalLength', this.focalLength, ...
            'minDepth', s.minDepth, 'maxDepth', s.maxDepth, ...
            'minScore', s.minScore, 'maxAreaRatio', s.maxAreaRatio, ...
            'minAreaRatio', s.minAreaRatio, ...
            'minScoreForMultipleMatches', s.minScoreForMultipleMatches ...
        );

        d = double(data.matchData.disparity); % (px) > 0
        xl = trackedParticlesData.centroid(:, 1); % (px) > 0
        yl = trackedParticlesData.centroid(:, 2); % (px) > 0

        X = this.baseLine./d.*(xl - this.principalPoint(1));
        Y = this.baseLine./d.*(yl - this.principalPoint(2));
        Z = this.baseLine./d*this.focalLength;

        this.step.tracks.disparity(rowsToUpdate) = d; % px
        this.step.tracks.worldCoordinates(rowsToUpdate, 1) = X;
        this.step.tracks.worldCoordinates(rowsToUpdate, 2) = Y;
        this.step.tracks.worldCoordinates(rowsToUpdate, 3) = Z;

        I = find(~isnan(data.matchData.rightParticleId));
        validCount = length(I);

        this.logStatus(sprintf('Step #%d - Estimated coordinates of %d/%d', ...
           this.step.counter, validCount, length(trackedParticlesIds)), false);
    end
    
    this.logStatus(sprintf('Step #%d - Triangulation took %.3f seconds', ...
        this.step.counter, toc), false);
end

