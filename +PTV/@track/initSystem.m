function [this] = initSystem(this)
%INITSYSTEM Initialises the system objects (for players, foreground and 
% blobs detection, step and system).
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    %% Check toolboxes
    if(~license('test', 'Image_Toolbox'))
        error('Please install the Image Toolbox');
    end
    if(~license('test', 'video_and_image_blockset'))
        error('Please install the Vision Toolbox');
    end
        
    %% Check directory existance
    if(~(exist(this.leftCameraPath,'dir')))
        error('Cannot find %s', this.leftCameraPath);
    end
    
    if(~(exist(this.rightCameraPath,'dir')))
        error('Cannot find %s', this.rightCameraPath);
    end
    
    % add path for OpenCV
    if(~exist(this.mexopencvPath, 'dir'))
        error('The provided path to mexopencv does not exist');
    else
        addpath(this.mexopencvPath, fullfile(this.mexopencvPath, 'opencv_contrib'));
    end
    
    %% Create log file
    this.logFolder = fullfile(this.leftCameraPath, '../logs');
    if(~(exist(this.logFolder,'dir')))
        mkdir(this.logFolder)
    end
    
    this.dateFmt = datestr(now, 'yyyymmdd_HHMMSS');
    fileName = sprintf('info_%s.log', this.dateFmt);
    this.logFile = fullfile(this.logFolder, fileName);
    if(this.enableLogging)
        fclose(fopen(this.logFile, 'w'));
    end
    
    %% Load files
    this.video.leftVideos = this.loadFiles(this.leftCameraPath, this.videoFileExtension);
    this.video.rightVideos = this.loadFiles(this.rightCameraPath, this.videoFileExtension);
    this.video.total = length(this.video.leftVideos);
    
    if(this.video.total ~= length(this.video.rightVideos))
        error('The number of videos in %s is different from the videos found in %s', ...
            this.leftCameraPath, this.rightCameraPath);
    end
    if(this.startingVideo > this.video.total)
        error('''startingVideo'' must be less than %d', this.video.total);
    end

    this.logStatus(sprintf('Reading ''%s'' folder for left camera', this.leftCameraPath), false);
    this.logStatus(sprintf('Reading ''%s'' folder for right camera', this.rightCameraPath), false);
    
    text = sprintf('Found the following videos\n');
    for s=1:length(this.video.leftVideos)
        text = [text sprintf('\t L: %s => R: %s\n', this.video.leftVideos{s}.fileName, ...
            this.video.rightVideos{s}.fileName)];
    end
    this.logStatus(text(1:end-1));
    
    %% Video object
    % Create two this.video players, one to display the video, and one to display 
    % the foreground mask.
    if(this.showVideoPlayers)
        this.video.maskPlayer = vision.VideoPlayer('Name', 'Left frame mask', ...
            'Position', [740, 400, 700, 400]);
        this.video.videoPlayer = vision.VideoPlayer('Name', 'Left frame', ...
            'Position', [20, 400, 700, 400]);
    end

    %% GUI
    if(~this.noGUI)
        this = this.progressWindow();
    end
    
    %% Initiliase the foreground detector. It separates moving particles from
    % the background by creating a binary mask. The mask contains 1 for the 
    % foreground and 0 for the background.
    b = this.blobDetectionSettings;
    this.video.leftDetector = vision.ForegroundDetector('NumTrainingFrames', ...
        this.numberOfTrainingFrames);
    this.video.rightDetector = vision.ForegroundDetector('NumTrainingFrames', ...
        this.numberOfTrainingFrames);
    if(isfield(b, 'minimumBackgroundRatio'))
        this.video.leftDetector.MinimumBackgroundRatio = b.minimumBackgroundRatio;
        this.video.rightDetector.MinimumBackgroundRatio = b.minimumBackgroundRatio;
    end

    %% Blob object
    % Connected groups of foreground pixels are likely to correspond to moving
    % objects. The blob analysis system object is used to find such groups
    % (called 'blobs' or 'connected components').
    this.video.leftBlobAnalyser = vision.BlobAnalysis;
    this.video.rightBlobAnalyser = vision.BlobAnalysis;
    if(isfield(b, 'minimumBlobArea'))
        this.video.leftBlobAnalyser.MinimumBlobArea = b.minimumBlobArea;
        this.video.rightBlobAnalyser.MinimumBlobArea = b.minimumBlobArea;
    end
    if(isfield(b, 'maximumBlobArea'))
        this.video.leftBlobAnalyser.MaximumBlobArea = b.maximumBlobArea;
        this.video.rightBlobAnalyser.MaximumBlobArea = b.maximumBlobArea;
    end
    
    this.video.leftBlobAnalyser.MaximumCount = this.blobDetectionSettings.maximumCount;
    this.video.rightBlobAnalyser.MaximumCount = this.blobDetectionSettings.maximumCount;
    
    % export other data
    fields = {'MajorAxisLengthOutputPort', 'MinorAxisLengthOutputPort', ...
        'OrientationOutputPort', 'EccentricityOutputPort', 'PerimeterOutputPort', ...
        'EquivalentDiameterSquaredOutputPort'};
    for fi=1:length(fields)
        f = fields{fi};
        this.video.leftBlobAnalyser.(f) = true;
        this.video.rightBlobAnalyser.(f) = true;
    end
    
    %% Status objects
    % Step object (see createNewTracks for the fields in 'tracks').
    this.step = struct('nextTrackId', 1, 'frameNumber', 0, 'time', 0, ...
        'counter', 0, 'tracks', table, 'leftParticles', table, 'rightParticles', table, ...
        'assignments', [], 'unassignedTracks', [], 'unassignedDetections', []);
    
    % System object
    this.system = [];

    %% Load stereo calibration
    this.logStatus(sprintf('Loading stereo calibration parameters ''%s''', ...
        this.stereoCalibrationFile));
    tmp = load(this.stereoCalibrationFile);
    this.stereoParams = tmp.stereoParams;
    if(~isa(this.stereoParams, 'stereoParameters'))
        error('Calibration file %s must be a ''stereoParameters'' object', ...
            this.stereoCalibrationFile);
    end
    this.unit = this.stereoParams.WorldUnits;
    
    % baseline (mm)
    this.baseLine = abs(this.stereoParams.TranslationOfCamera2(1));
    % NOTE: focal length (px) along x and y are different because 
    % pixels are not squares. Here we get an average among the two
    % The camera should have in principale the same focal length.
    % However the difference is very small, so get the average for
    % this as well.
    this.focalLength = nanmean([this.stereoParams.CameraParameters1.FocalLength ...
        this.stereoParams.CameraParameters2.FocalLength]);
    
    this.principalPoint = this.stereoParams.CameraParameters1.PrincipalPoint;
    
    % check disparity
    % image size is flipped in cameraParameters class
    imageSize = this.stereoParams.CameraParameters1.ImageSize([2 1]); 
    allowedMinDepth = this.baseLine*this.focalLength/imageSize(1);
    maxSetDisparity = this.baseLine*this.focalLength/this.matchParticlesSettings.minDepth;
    minSetDisparity = this.baseLine*this.focalLength/this.matchParticlesSettings.maxDepth;
    
    this.logStatus(sprintf('Min depth: %.2f mm - Max disparity: %.2f px (Max allowed: %.2f px)', ...
        this.matchParticlesSettings.minDepth, maxSetDisparity, imageSize(1)));
    this.logStatus(sprintf('Max depth: %.2f mm - Min disparity: %.2f px', ...
        this.matchParticlesSettings.maxDepth, minSetDisparity));
    
    if(this.matchParticlesSettings.minDepth < allowedMinDepth)
        error(['The set minimum depth of %.2f mm (with disparity of %.0f px) must be larger than ', ...
            'the allowed minimum depth of %.2f mm (with max disparity of %.0f px).'], ...
            this.matchParticlesSettings.minDepth, maxSetDisparity, ...
            allowedMinDepth, imageSize(1));
    end
    
    %% Match settings
    fields = {'minScore', 'maxAreaRatio', 'minAreaRatio', ...
        'minScoreForMultipleMatches', 'minDepth', 'maxDepth'};
    defaults = [.8 1.2 .8 .9 NaN NaN];
    for f=1:length(fields)
        name = fields{f};
        if(~isfield(this.matchParticlesSettings, name))
            this.matchParticlesSettings.(name) = defaults(f);
        end
    end

    %% Load lag file
    this.logStatus(sprintf('Loading lag parameters ''%s''', this.videoLagFile));
    lagConfig = load(this.videoLagFile);
    str = fieldnames(lagConfig);
    for i=1:length(str)
        this.lagSettings.(str{i}) = lagConfig.(str{i});
    end

    %% Create track data file
    fileName = sprintf('tracks_%s.txt', this.dateFmt);
    this.trackFile = fullfile(this.logFolder, fileName);
    this.trackFileCounter = 0;
    this.createTrackFile(this.trackFile);

    % step counter
    this.step.counter = 0;
    
    % frame when tracks were last saved
    this.lastSaved = 1;
    
    %% Get total number of frames from the concatenated and synced videos
    this = this.countVideoFrames();
    
    totLeftVideos = length(this.video.leftVideos);
    if(this.endingVideo > totLeftVideos)
        error('''endingVideo'' must be less than the total number of videos from left cameras (%d)', ...
                  totLeftVideos);
    end
end

