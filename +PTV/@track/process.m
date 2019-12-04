function [this] = process(this)
%PROCESS Analyses the frames
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    %% Find which video to start with based on the 'startVideoAtFrame'
    %  and 'this.video.startFrame' index of current open video file
    this.step.fileIndex.left = find(this.totFramesInPreviousVideos.left ...
        <= this.video.startFrame.left, 1, 'last');
    this.step.fileIndex.right = find(this.totFramesInPreviousVideos.right ...
        <= this.video.startFrame.right, 1, 'last');

    % load 1st set of videos
    currentFile.left = this.video.leftVideos{this.step.fileIndex.left};
    this.logStatus(sprintf('Loading video #%d from left camera (%s)', ...
        this.step.fileIndex.left, currentFile.left.fileName));
    this.video.left = this.readVideoFile(currentFile.left.fullFile);

    currentFile.right = this.video.rightVideos{this.step.fileIndex.right};
    this.logStatus(sprintf('Loading video #%d from right camera (%s)', ...
        this.step.fileIndex.right, currentFile.right.fileName));
    this.video.right = this.readVideoFile(currentFile.right.fullFile);

    %% Loop through the frames
    this.GUI.fig.Units = 'normalized';
    this.GUI.fig.Position(1) = 0.71; 
    this.GUI.fig.Position(2) = 0.64;
    fDect = waitbar(0, 'Plese wait...', 'Units', 'normalized', ...
        'Position', [0.71 0.36 0.1875 0.0625]);

    this.logStatus(sprintf('Skipping %d frames for foreground detection', ...
        this.numberOfTrainingFrames));

    avgTime = 0;
    for k=1:this.numberOfFrames.toProcess
        globalTimer = tic;

        %% Counters
        % new frame number based on new frame rate
        this.step.counter = this.step.counter + 1;

        % global index
        this.step.globalLeftFrame = this.frIdx.left(k);
        this.step.globalRightFrame = this.getSyncedFrame(this.step.globalLeftFrame);

        %% Open next files
        % Left camera
        if(this.step.globalLeftFrame >= this.totFramesInPreviousVideos.left(this.step.fileIndex.left+1))
            this.logStatus(sprintf('Reached end of left video #%d (%s)', ...
                this.step.fileIndex.left, currentFile.left.fileName));

            if(this.step.fileIndex.left+1 > this.video.total)
                break;
            end

            this.step.fileIndex.left = this.step.fileIndex.left + 1;
            currentFile.left = this.video.leftVideos{this.step.fileIndex.left};

            this.logStatus(sprintf('Opening next left video #%d (%s)', ...
                this.step.fileIndex.left, currentFile.left.fileName));  

            this.video.left = this.readVideoFile(currentFile.left.fullFile);

        end

        % Right camera
        if(this.step.globalRightFrame >= this.totFramesInPreviousVideos.right(this.step.fileIndex.right+1))
            this.logStatus(sprintf('Reached end of right video #%d (%s)', ...
                this.step.fileIndex.right, currentFile.right.fileName));

            if(this.step.fileIndex.right+1 > this.video.total)
                break;
            end

            this.step.fileIndex.right = this.step.fileIndex.right + 1;
            currentFile.right = this.video.rightVideos{this.step.fileIndex.right};

            this.logStatus(sprintf('Opening next right video #%d (%s)', ...
                this.step.fileIndex.right, currentFile.right.fileName));   
            this.video.right = this.readVideoFile(currentFile.right.fullFile);
        end

        %% Relative frame in the current video set
        this.step.leftFrameId = this.step.globalLeftFrame - ...
            this.totFramesInPreviousVideos.left(this.step.fileIndex.left);
        this.step.rightFrameId = this.step.globalRightFrame - ...
            this.totFramesInPreviousVideos.right(this.step.fileIndex.right);

        %% Progress info
        % global
        frac = k/this.numberOfFrames.toProcess;
        avgDuration = this.formatDuration(avgTime);
        
        set(this.GUI.labels.global.Step, 'String', ...
            sprintf('%d/%d (%d%%)', k, this.numberOfFrames.toProcess, round(frac*100)));
        set(this.GUI.labels.global.TotalTracks, 'String', sprintf('%d/%d', ...
            height(this.step.tracks), this.maxTracks));
        set(this.GUI.labels.global.MeanTime, 'String', sprintf('%.3f seconds', avgTime));
        set(this.GUI.labels.global.LeftTime, 'String',  sprintf('%s', ...
            (this.numberOfFrames.toProcess - k) * avgDuration));

        % left video
        yy = this.numberOfFrames.left(this.step.fileIndex.left);
        fracL = this.step.leftFrameId/yy;

        set(this.GUI.labels.leftVideo.OpenVideo, 'String', ...
            sprintf('#%d - %s', this.step.fileIndex.left, currentFile.left.fileName));
        set(this.GUI.labels.leftVideo.CurrentFrame, 'String',  ...
            sprintf('%.0f/%d (%d%%)', this.step.leftFrameId, yy, round(fracL*100)));
        set(this.GUI.labels.leftVideo.LeftTime, 'String', sprintf('%s', ...
            (round(yy - this.step.leftFrameId)/this.video.actualFrameStep) * avgDuration));
        
        % right video
        yy = this.numberOfFrames.right(this.step.fileIndex.right);
        fracR = this.step.rightFrameId/yy;
        
        set(this.GUI.labels.rightVideo.OpenVideo, 'String', ...
            sprintf('#%d - %s', this.step.fileIndex.right, currentFile.right.fileName));
        set(this.GUI.labels.rightVideo.CurrentFrame, 'String', ...
            sprintf('%.0f/%d (%d%%)', this.step.rightFrameId, yy, round(fracR*100)));
        set(this.GUI.labels.rightVideo.LeftTime, 'String', sprintf('%s', ...
            (round(yy - this.step.rightFrameId)/this.video.actualFrameStep) * avgDuration));

        %% Read both frames
        this = this.readStereoFrames(this.step.leftFrameId, this.step.rightFrameId);

        % check if frames are valid otherwise skip
        if(~this.step.isLeftFrameValid)
             this.logStatus(sprintf('[!!] Step #%d - Frame #%d in left video #%d (%s) is not valid. Skipped', ...
                this.step.counter, this.step.leftFrameId, ...
                this.step.fileIndex.left, currentFile.left.fileName));

            continue;
        end
        if(~this.step.isRightFrameValid)
             this.logStatus(sprintf('[!!] Step #%d - Frame #%d in right video #%d  (%s) is not valid. Skipped', ...
                this.step.counter, this.step.rightFrameId, ...
                this.step.fileIndex.right, currentFile.right.fileName));

            continue;
        end

        %% Rectify frames
        [this.step.leftFrame, this.step.rightFrame] = ...
            rectifyStereoImages(this.step.leftFrame, this.step.rightFrame, this.stereoParams);

        %% Apply custom transformation
        if(isa(this.transformFrames, 'function_handle'))
            [this.step.leftFrame, this.step.rightFrame] = ...
                this.transformFrames(this.step.leftFrame, this.step.rightFrame);
        end

        %% Particle detection
        this = detectParticles(this);

        set(this.GUI.labels.leftVideo.TotalParticles, 'String', sprintf('%d/%d', ...
            height(this.step.leftParticles), this.blobDetectionSettings.maximumCount));
        set(this.GUI.labels.rightVideo.TotalParticles, 'String', sprintf('%d/%d', ...
            height(this.step.rightParticles), this.blobDetectionSettings.maximumCount));
        drawnow;
        
        % train the foreground detection algorithm and skip these frames
        if(k <= this.numberOfTrainingFrames)
            fracDet = k/this.numberOfTrainingFrames;
            waitbar(fracDet, fDect, sprintf('Skipping frames %d/%d for training (%d%%)', ...
                k, this.numberOfTrainingFrames, round(fracDet*100)));

            continue;
        elseif(k == this.numberOfTrainingFrames+1)
            close(fDect);
            this.logStatus('Training done');
            this.logStatus('Tracking started');
            
            % step counter
            this.step.counter = 1;
        end
        
        % global time
        this.step.time = this.step.counter/this.video.actualFrameRate;
        
        % check that there are particle to tirnagulate
        if(isempty(this.step.leftParticles) || isempty(this.step.rightParticles))
            this.logStatus(sprintf('[!!] Step #%d - No particles found in one of the frames', ...
                this.step.counter));
            continue;
        end
   
        % Simulate particle location
        this = this.predictNewParticleLocations();
  
        % Assign tracks to measurements
        this = this.assignDetectionsToCurrentTracks();

        % Assigned tracks
        this = this.updateAssignedTracks();

        % New detected particles. This can be either a new particle or a
        % detection not assigned to an existing track because of the settings
        % in the cost function
        this = this.createNewTracks();

        % Unassigned tracks. Add them to the system object but do not estimate
        % their depth
        this = this.updateUnassignedTracks();

        % Log total tracks
        this.logStatus(sprintf('Step #%d - Analysing %d active tracks', ...
            this.step.counter, height(this.step.tracks)), false);

        % Get disparity and real-world coordinates for assigned and
        % new tracks
        this = this.trianguateParticles();

        % Estimate particle lengths
        this = this.estimateParticleLengths();

        %% Update and clean up
        % Hides tracks that have been invisible for too many consecutive frames
        this = this.markLostTracks();

        % Upate system for exporting
        this = this.updateSystem();
         
        % Export and clean up lost tracks
        this = this.autoSave();

        % Remove lost tracks from this.step.tracks
        this = this.cleanUp();

        %% Display
        if(this.showVideoPlayers && ~this.GUI)
            this.displayTracks();
        end

        timeTaken = toc(globalTimer);
        this.logStatus(sprintf('Step #%d - Took %.3f overall seconds', ...
            this.step.counter, timeTaken), false);
        avgTime = nanmean([avgTime timeTaken]);
    end
end

