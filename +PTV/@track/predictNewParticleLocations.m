function [this] = predictNewParticleLocations(this)
%PREDICTNEWPARTICLESLOCATION predicts the locations of existing
%particles/system.tracks in the current frame by using the Kalman filter. 
%The predicted position is added to the current track. If the track is
%later associated with a particle, the centroid and the bbox are replaced
%with the real one; otherwise the alghoritm keeps using the estimated track
%as long as the track is visible.
% The following track data are modified:
%
%   - centroid: predicted centroid fromt he Kalman filter.
%   - bbox: predicted boundary box fromt he Kalman filter.
%   - currentLeftparticleId: set to NaN
%   - estimated: set to 1; data have been estimated via the Kalman filter.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    for i=1:height(this.step.tracks)
        % Predict the current location of the track (the kalmanFilter
        % object is initially empty for the first frame)
        predictedCentroid = predict(this.step.tracks.kalmanFilter{i});

        % Set centroid with the predicted location.
        % If the detection is later assigned to a track, the bbox
        % and centroid are replaced with the correct detcted values 
        % from the blob. Otherwise the detection is plotted as prediction.
        this.step.tracks.centroid(i, :) = predictedCentroid;
        
        % Set the predicted bounding box.
        % bbox is [x y width height] where[x y] represents the upper left 
        % corner of the bounding box. Using the size of the bbox at the
        % previous step since this.step.tracks(i).bbox is not up-to-date yet.
        bbox = this.step.tracks.bbox(i, :);
        x = int32(predictedCentroid(1)) - bbox(3)/2;
        y = int32(predictedCentroid(2)) - bbox(4)/2;
        this.step.tracks.bbox(i, :) = [x y bbox(3:4)];
        
        % Update 'currentLeftparticleId' and other parameter values not to 
        % keep value from previous track
        this.step.tracks.currentLeftparticleId(i) = NaN;
        this.step.tracks.area(i) = NaN;
        this.step.tracks.ax_mj(i) = NaN;
        this.step.tracks.ax_mn(i) = NaN;
        this.step.tracks.or(i) = NaN;
        this.step.tracks.ecc(i) = NaN;
        this.step.tracks.r2(i) = NaN;
        this.step.tracks.per(i) = NaN;
        
        this.step.tracks.estimated(i) = 1;
    end
end

