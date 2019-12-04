function [] = displayTracks(this)
%DISPLAYTRACKS Displays tracking results.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    % Convert the frame to uint8 RGB.
    this.step.leftFrame = im2uint8(this.step.leftFrame);
    % Convert the mask from logical RGB (b/w)
%     this.step.leftMask = uint8(repmat(this.step.leftMask, [1, 1, 3])).*255;
    % Overlap mask to image so that background is black
    this.step.leftMask = this.step.leftFrame.*repmat(uint8(this.step.leftMask), [1, 1, 3]);

    % Plot tracks that have at least 8 positions available
    minVisibleCount = 8;
    if(~isempty(this.step.tracks) && ~isempty(this.system))
        % Noisy detections tend to result in short-lived tracks.
        % Only display tracks that have been visible for more than 
        % a minimum number of frames.
        reliableTrackInds = this.step.tracks.totalVisibleCount > minVisibleCount;
        reliableTracks = this.step.tracks(reliableTrackInds, :);

        % Display the objects. If an object has not been detected
        % in this frame, display its predicted bounding box.
        if(~isempty(reliableTracks))
            % Get bounding boxes.
            bboxes = cat(1, reliableTracks.bbox);

            % Get ids.
            ids = int32(reliableTracks.id)';

            cols = vertcat(reliableTracks.colour);
            
            % Create labels for objects indicating the ones for 
            % which we display the predicted rather than the actual 
            % location.
            labels = cellstr(int2str(ids'));
            % for not assigned track, the location is not replaced with the
            % real one because it is not available
            %TODO: this works but use .estimated
            predictedTrackInds = reliableTracks.consecutiveInvisibleCount > 0;
            isPredicted = cell(size(labels));
            isPredicted(predictedTrackInds) = {' predicted'};
            labels = strcat(labels, isPredicted);

            % Plot tracks using the last 20 available locations
            lastLocation = 20;
            for i=1:height(reliableTracks)
                idx = reliableTracks.id(i);
                systemIdx = this.system.trackId == idx;

                a = this.system(systemIdx, :);
                tot = height(a);
                range = tot:-1:max([1 tot-lastLocation]);

                siz = length(range)*2;
                pos = NaN(1, siz);
                pos(1, 1:2:siz) = a.x(range);
                pos(1, 2:2:siz) = a.y(range);

                pos = pos(pos ~= 0);
                pos = pos(~isnan(pos)); % remove pair-wise NaN positions
                col = reliableTracks.colour(i, :);
                this.step.leftMask = insertShape(this.step.leftMask, 'line', pos, ...
                    'Color', col);
                this.step.leftFrame = insertShape(this.step.leftFrame, 'line', pos, ...
                    'Color', col);
            end

            % Draw bounding boxes and labels
            this.step.leftMask = insertObjectAnnotation(this.step.leftMask, 'rectangle', ...
                bboxes, labels, 'Color', cols, ...
                'TextColor', 'black');

            this.step.leftFrame = insertObjectAnnotation(this.step.leftFrame, 'rectangle', ...
                bboxes, labels, 'Color', cols, ...
                'TextColor', 'black');
        end
    end
    
    % Print number of tracked particles on screen
    t = this.step.leftFrameId/this.video.originalFrameRate;
    mins = floor(t/60);
    timestamp = sprintf('%d:%.3f', mins, t-mins*60);
    this.step.leftMask = insertText(this.step.leftMask, [5 7], ...
        sprintf('V%d %s - %d/%d tracks', this.step.fileIndex.left, ...
        timestamp, height(reliableTracks), height(this.step.tracks)), ...
        'TextColor', 'white', 'FontSize', 30, 'BoxColor', 'red');  
    this.step.leftFrame = insertText(this.step.leftFrame, [5 7], ...
        sprintf('V%d %s -  %d/%d tracks', this.step.fileIndex.left, ...
        timestamp, height(reliableTracks), height(this.step.tracks)), ...
        'TextColor', 'white', 'FontSize', 30, 'BoxColor', 'blue');
    
    % Update the players
    this.video.maskPlayer.step(this.step.leftMask);        
    this.video.videoPlayer.step(this.step.leftFrame);
end

