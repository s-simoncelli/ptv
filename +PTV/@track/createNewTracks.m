function [this] = createNewTracks(this)
%CREATENEWTRACKS Creates new tracks from unassigned detections in the
% step.tracks object.
% This function is also used to initialise particles found in the 1st frame
% with the Kalman filter when this.step.tracks is empty. 
% Available track data are:
%    
%   TRACK DATA
%   - id: track ID
%   - kalmanFilter: Kalman filter object
%   - age: number of frames since the track was first detected
%   - totalVisibleCount:  number of frames when the track was ivisible
%   - consecutiveInvisibleCount: number of consecutive frames when the track 
%       was inivisible
%   - estimated: whether the centroid and bbox were estimated. This happens
%      when the track is not assinged to any detection in the left frame.
%   - colour: track colour
%
%   CURRENT PARTICLE DATA ASSIGNED TO TRACK
%   - currentLeftparticleId: ID of detected particle in left frame
%   - centroid: particle centroid
%   - bbox: particle boundary box
%   - length: particle length
%   - disparity: particle disparity
%   - worldCoordinates: 3x1 matrix with particle in world coordinate unit. 
%     The unit is that used in the calibration chequerboard (see stereoParamters)
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    centroids = this.step.leftParticles.centroid(this.step.unassignedDetections, :);
    bboxes = this.step.leftParticles.bbox(this.step.unassignedDetections, :);
    areas = this.step.leftParticles.area(this.step.unassignedDetections);
    ids = this.step.leftParticles.id(this.step.unassignedDetections);
    
    ax_mjs = this.step.leftParticles.ax_mj(this.step.unassignedDetections);
    ax_mns = this.step.leftParticles.ax_mn(this.step.unassignedDetections);
    ors = this.step.leftParticles.or(this.step.unassignedDetections);
    eccs = this.step.leftParticles.ecc(this.step.unassignedDetections);
    r2s = this.step.leftParticles.r2(this.step.unassignedDetections);
    pers = this.step.leftParticles.per(this.step.unassignedDetections);

    newTrackCount = 0;
    for i=1:size(centroids, 1)
        % when system saturates stop adding new tracks
        if(height(this.step.tracks) >= this.maxTracks)
            continue;
        end
        
        centroid = centroids(i, :);
        bbox = bboxes(i, :);
        area = double(areas(i, :));

        % Create a Kalman filter object for new detections only.
        kalmanFilter = configureKalmanFilter(this.kalmanSettings.motionModel, ...
            centroid, this.kalmanSettings.initialEstimateError, ...
            this.kalmanSettings.motionNoise, ...
            this.kalmanSettings.measurementNoise);

        % Create a new track
        newTrack = table(this.step.nextTrackId, {kalmanFilter}, 1, 1, 0, 0, ...
             255*rand(3, 1)', ids(i), centroid, bbox, area, NaN, ...
             pers(i), ax_mjs(i), ax_mns(i), ors(i), eccs(i), r2s(i), ...
             [NaN NaN NaN], [NaN NaN], 0, false,...
            'VariableNames', {'id', 'kalmanFilter', 'age',  'totalVisibleCount', ...
            'totalInvisibleCount', 'consecutiveInvisibleCount', 'colour', ...
            'currentLeftparticleId', 'centroid', 'bbox', 'area', 'disparity', ...
            'per', 'ax_mj', 'ax_mn', 'or', 'ecc', 'r2', ...
            'worldCoordinates', 'length', 'estimated', 'lost'
        });

        % Add it to the array of system.tracks.
        this.step.tracks = [this.step.tracks; newTrack];

        % Increment the next id
        this.step.nextTrackId = this.step.nextTrackId + 1;
        newTrackCount = newTrackCount + 1;
    end

    omitted = length(this.step.unassignedDetections) - newTrackCount;
    this.logStatus(sprintf('Step #%d - Created %d new tracks. Skipped %d', ...
       this.step.counter, newTrackCount, omitted), false);  
   
    this.logStatus(sprintf('Step #%d - Creating new tracks took %.3f seconds', ...
        this.step.counter, toc), false);
end
