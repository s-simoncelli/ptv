function [this] = assignDetectionsToCurrentTracks(this)
%ASSIGNDETECTIONSTOTRACKS Assings the detected centroids to a track in the
%current frame. 
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    nTracks = height(this.step.tracks);
    nDetections = height(this.step.leftParticles);

    % Compute pair-wise distances between estimated and predicted positions.
    % Rows contain each track, columns the distance of each detection
    % from that track last position.
    % Compute the cost of assigning each detection to each track.
    cost = zeros(nTracks, nDetections);
    for i=1:nTracks
        cost(i, :) = distance(this.step.tracks.kalmanFilter{i}, ...
            this.step.leftParticles.centroid);
    end
    
    % Filter out larger distances
    % Set distance=Inf when cost > costOfNonAssignment, so that those tracks
    % will never be assigned. When cost is Inf, the 'munkres' function removes
    % these data.
    cost(cost > this.kalmanSettings.costOfNonAssignment) = Inf;
    
    save(...
        sprintf('/Volumes/PTV #2/2019_Stechin_zooflux/Cameras/deployment_1/test_assignement/data_%d.mat', this.step.counter),...
        'cost');
    % This is faster than MATLAB's implementation
    % 'assignDetectionsToTracks'
    idx = this.munkres(cost);

    % get map tracks => detections and remove unassigned tracks when idx=0
    this.step.assignments = [1:length(idx); idx]';
    I = this.step.assignments(:, 2) == 0;
    this.step.assignments(I, :) = [];
    
    % get indexes assignments(:, 1) when idx=0 for unassigned tracks 
    this.step.unassignedTracks = find(idx == 0);
    
    % unassigned detections
    this.step.unassignedDetections = setdiff(1:nDetections, ...
        this.step.assignments(:, 2));
    
    this.logStatus(sprintf('Step #%d - Assignment took %.3f seconds', ...
        this.step.counter, toc), false);
    
    this.logStatus(...
        sprintf('Step #%d - Assigned tracks: %d - unassigned tracks: %d - unassigned detections: %d', ...
        this.step.counter, length(this.step.assignments), ...
        length(this.step.unassignedTracks), ...
        length(this.step.unassignedDetections)), ...
    false);
end
