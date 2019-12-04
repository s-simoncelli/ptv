classdef track
%TRACK Tracks particles from a stereo rig. Usage:
%
%  obj = PTV.track(calibrationFile, leftCameraPath, rightCameraPath, ...
%     videoLagParamsFile, mexopencvPath, blobDetectionSettings, trackDetectionSettings, ...
%     kalmanSettings, matchParticlesSettings) returns a 'track' object with
%     the following inputs:
%
%   calibrationFile      
%       Path to calibration file. This must be a stereoParameters object either 
%       generated from 'stereoCameraCalibrator' or the 'visionToolboxCalibration' 
%       in the PTV package
%
%   leftCameraPath       
%       Path to videos shot from the left camera
%
%   rightCameraPath      
%       Path to videos shot from the right camera
%
%   videoLagFile
%       Path to lag data generated from the syncVideos.save() method in the PTV package
%
%   mexopencvPath      
%       Path to mexopencv files
%
%   blobDetectionSettings   
%      Struct array with options for the blob detection. See vision.BlobAnalysis 
%      for the option explanation. Example: 
%       
%       blobDetectionSettings = struct('minimumBackgroundRatio', 0.4, ...
%         'minimumBlobArea', 10, 'maximumBlobArea', 200, 'maximumCount', 600);
%
%       If 'minimumBlobArea' is too large, small particles close to the
%       cameras or large and far-away particles may not be detected. If 
%       'minimumBlobArea' is instead too small, you might track background
%       variations that are not particles, but small variations in ligth
%       intensity.
%       If 'maximumCount' is too small, some particles may not be tracked
%       in some areas of the image. Make sure to detect as many particle as
%       possible. Change this values based on the number of particles
%       expected in the system, 'minimumBlobArea' and 'maximumBlobArea'.
% 
%   trackDetectionSettings  
%       Struct array with options for track detection settings. Example: 
%
%        trackDetectionSettings = struct('visibilityRatio', 0.6, 'ageThreshold', 8, ...
%          'invisibleForTooLong', 20);
%
%        A track is regarded as visible when a particle is associated to it.  
%        A tracks is considered lost or invisible when no particles are
%        associated to it for too many consecutive frames. Lost tracks
%        identify particles that exist the FOV and are not visible anymore,
%        or particles that are not detected anymore by the blob analysis
%        algorithm. A track is defined as lost when one of the following 
%        conditions occur:
%           1) the track age (defined as number of frames since the track was  
%              first detected) is between than 'ageMin' and 'ageMax' and 
%              their visibility (defined as the fraction of the track's age
%              for which it was  visible) is less than 'visibilityRatio'. 
%              This criterion identifies young tracks that have been 
%              invisible for too many frames. 'ageMin' ensures not to
%              remove tracks immediately. For example if age = 2 and the
%              track was invisible for 1 frame, visibility would .5 and the track
%              would be removed if visibilityRatio = 0.6.
%              In the example the number of non consecutive frames for which 
%              the track was invisible is 0.6*8 ~ 5 frames.
%           2) the number of consecutive frames when the track was
%              invisible is greater or equal to 'invisibleForTooLong'.
%              This helps to identify particles that left the system and
%              whose track is not traceable anymore. 
%         
%   kalmanSettings
%      Struct array with options for the Kalman algorithm settings. 
%      See configureKalmanFilter for the option explanation. Example: 
%       
%       kalmanSettings = struct('costOfNonAssignment', 20, 'motionModel',  ...
%         'ConstantVelocity', 'initialEstimateError', [200 50], ...
%         'motionNoise', [30 25], 'measurementNoise', 20);              
% 
%      The 'costOfNonAssignment' value should be tuned experimentally. A
%      too low value increases the likelihood of creating a new track, and
%      lead to track fragmentation. A too high threshold may result in a
%      single track corresponding to a series of separate moving objects.
%
%   matchParticlesSettings
%      Struct array with options for match particle algorithm. For the
%      options see the 'particleMatching' class in the PTV package.  Example:
% 
%       matchParticlesSettings = struct('minScore', .8, 'maxAreaRatio', 1.1, ...
%         'minAreaRatio', .9, 'subFramePadding', 15, 'searchingAreaPadding', 30);
% 
%
%   obj = PTV.track(..., 'PropertyName', PropertyValue) specifies additional 
%   name-value pairs  described below:
%
%   'frameRate'             Down-sample the videos using a new frame rate 
%                           instead of processing all the available frames
%
%                           Default: []
%
%   'startingVideo'         Number of video from left camera to start 
%                           processing in the set
%
%                           Default: 1
%
%   'videoFileExtension'    Extension of the video files 
%
%                           Default: 'MP4'
%
%   'startingTime'          Number of seconds from the 'startingTime' video 
%                           when to start processing the frames 
%
%                           Default: 0
%
%   'numberOfTrainingFrames'    Number of frames to use for training the 
%                               foreground algorithm. See
%                               'NumTrainingFrames' in vision.ForegroundDetector
% 
%                               Default: 100
%
%   'rotateLeftFrame'       Whether to rotate the left frame
%
%                           Default: false
%
%   'rotateRightFrame'      Whether to rotate the right frame
%
%                           Default: false
%
%   'transformFrames'       Function handle to transform frames. This function
%                           is called after rectifying the stereo frames to
%                           crop or deform them. The inputs and outputs of 
%                           this function are the left and right rectified
%                           frames as array.
%
%                           Default: []
%
%   'showVideoPlayers'      Show video players with tracks. This may
%                           increase the processing time of each frame
%                           depending on the number of tracks to plot.
%
%                           Default: false
%
%   'enableLogging'         Write log messages into a .log file
%
%                           Default: true
%
%   'autoSaveEvery'         Auto save tracking data every 'autoSaveEvery' 
%                           processed frames
%
%                           Default: 10
%
%   'minDepth'              Minimum detectable depth of stereo rig in real-world
%                           units. This must have the same unit used in the
%                           calibration. This option is used to impose a
%                           maximum disparity when matching particles.
%
%                           Default: []
%
%   'maxTracks'             Maximum number of tracks to track. Once the
%                           system saturates, new discovered tracks are not
%                           added into the system anymore. New tracks will
%                           be added only when one more more track are
%                           marked as lost and removed from the system.
%                           Increasing this value, may increase the
%                           processing time, in particular in relation to the
%                           Hungarian alghoritm.
%
%                           Default: 400
%
%   'noGUI'                 Do not display GUI elements in case you want to
%                           run the tracking algorithm without MATLAB's GUI 
%                           (i.e. with the -nojvm option)
%
%   obj = PTV.track(...) returns a track object containing the following 
%   public properties:
%
%      trackFile      - Path to saved tracks
%      logFile        - Path to log file
%      numberOfFrames - Total number of frames in videos
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    properties (GetAccess = private, SetAccess = private)  
        % path to calibration file. This must be a stereoParameters object
        % either generated from 'stereoCameraCalibrator' or the 
        % visionToolboxCalibration in the PTV package
        stereoCalibrationFile

        % path to videos shot from the left camera
        leftCameraPath 

        % path to videos shot from the right camera
        rightCameraPath 

        % path to lag data generated from the syncVideos class in the PTV
        % package
        videoLagFile

        % path to mexopencv files
        mexopencvPath

        % enable logging
        enableLogging
       
        % down-sample the videos using a new frame rate instead of
        % processing all the avilable frames
        frameRate

        % video number to start with 
        startingVideo
        
        % number of seconds (from left camera) when to start processing the 
        % frames in video number 'startingVideo'
        startingTime
        
        % video number to end with 
        endingVideo
        
        % number of seconds (from left camera) when to stop processing the 
        % frames in video number 'endingVideo'
        endingTime

        % blob detection settings
        blobDetectionSettings

        % track detection settings
        trackDetectionSettings
  
        % Kalman algohritm settings
        kalmanSettings                      

        % match particle alghoritm settings
        matchParticlesSettings
        
        % stereo parameters
        stereoParams
       
        % lag settings
        lagSettings
        
        % number of frames to use for training the foreground algorithm
        numberOfTrainingFrames

        % transform frames according to function handle
        transformFrames
        
        % Show video players
        showVideoPlayers
        
        % whether to rotate the left frame
        rotateLeftFrame
        
        % whether to rotate the right frame
        rotateRightFrame

        % auto save tracking data every 'autoSaveEvery' processed frames
        autoSaveEvery
        
        % maximum number of tracks to track
        maxTracks
        
        % maximum size (in MB) of track file. After this limit, the file is
        % splitted
        maxTrackFileSize
        
        % Extension of the video files
        videoFileExtension
        
        % Display the GUI
        noGUI
    end
    
    properties (GetAccess = public, SetAccess = private)  
       % track data file
       trackFile
       
       % path to log file
       logFile
        
       % total number of frames in videos
       numberOfFrames
       
       % unit for measurements
       unit
    end
    
    properties (Access = private)
       % date format for log files
       dateFmt
       
       % folder where log files are stored
       logFolder
       
       % video data
       video 
       
       % step data
       step 
        
       % system data
       system
        
       % frame number when data are last saved
       lastSaved
       
       % stereo rig focal length (px)
       focalLength
        
       % stereo rig baseline (world units)
       baseLine
        
       % principal point coordinates of left camera (px)
       principalPoint
       
       % counter for number of track files
       trackFileCounter
       
       % frame numbers to be processed
       frIdx
       
       % cumulative frames from videos
       totFramesInPreviousVideos
       
       % summary window
       GUI
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        function this = track(varargin)            
            [this.stereoCalibrationFile, this.leftCameraPath, this.rightCameraPath, ...
            this.videoLagFile, this.mexopencvPath, ...
            this.blobDetectionSettings, this.trackDetectionSettings, ...
            this.kalmanSettings, this.matchParticlesSettings, this.showVideoPlayers, ...
            this.rotateLeftFrame, this.rotateRightFrame, this.enableLogging, ...
            this.video.frameRate, this.startingVideo, this.startingTime, ...
            this.endingVideo, this.endingTime, this.numberOfTrainingFrames, ...
            this.transformFrames, this.autoSaveEvery, ...
            this.maxTracks, this.videoFileExtension, ...
            this.maxTrackFileSize, this.noGUI] = validateAndParseInputs(varargin{:}); 
            
            %% Init
            if(~this.noGUI)
                delete(findall(0, 'type', 'figure', 'tag', 'TMWWaitbar'));
                delete(findall(0, 'type', 'figure', 'tag', 'spcui_scope_framework'));
                close all;
            end
            
            this = this.initSystem();

            %% Find the starting frame in each video set
            this.logStatus(this.lagSettings.lagMessage);
            [~, leftVideoProps] = this.readVideoFile(this.video.leftVideos{this.startingVideo}.fullFile);
            startVideoAtFrame = round(this.startingTime*leftVideoProps.frameRate);
            
            if(startVideoAtFrame > this.numberOfFrames.left(this.startingVideo))
                secs = seconds(startVideoAtFrame/leftVideoProps.frameRate);
                error('''startingTime'' must be less than the duration of the synchronised #%d video (%s)', ...
                    this.startingVideo, this.formatDuration(secs));
            end
            if(startVideoAtFrame < this.lagSettings.lag.F1(1))
                startingTimeMin = seconds(this.lagSettings.lag.F1(1)/leftVideoProps.frameRate);
                error('''startingTime'' must be larger than %s or %d frames to ensure video synchronisation', ...
                    this.formatDuration(startingTimeMin), this.lagSettings.lag.F1(1));
            end

            % 'startVideoAtFrame' is relative to the video. Convert it to
            % global frame number
            this.video.startFrame.left = startVideoAtFrame + ...
                this.totFramesInPreviousVideos.left(this.startingVideo);
            this.logStatus(sprintf('Left video will start from frame #%.0f', ...
                this.video.startFrame.left));
            
            this.video.startFrame.right = this.getSyncedFrame(this.video.startFrame.left);
            this.logStatus(sprintf('Right video will start from frame #%.0f', ...
                this.video.startFrame.right));

            %% Find the ending frame in each video set
            % set 'endingVideo' and 'endingTime' if NaN
            if(isnan(this.endingVideo) || isnan(this.endingTime))
                this.video.endFrame.left = this.lagSettings.lag.F1(end);
                this.video.endFrame.right = this.lagSettings.lag.F2(end);
            else
                endVideoAtFrame = round(this.endingTime*leftVideoProps.frameRate); 
                maxFrameNum = this.lagSettings.lag.F1(end) - this.totFramesInPreviousVideos.left(this.endingVideo);
                if(endVideoAtFrame > maxFrameNum)
                    secsIn = seconds(endVideoAtFrame/leftVideoProps.frameRate);
                    secsMax = seconds(maxFrameNum/leftVideoProps.frameRate);
                    error('''endingTime'' (%s) must be less than the maximum duration of the synchronised #%d video (%s) to ensure video synchronisation', ...
                        this.formatDuration(secsIn), this.endingVideo, ...
                        this.formatDuration(secsMax));
                end
                % 'endVideoAtFrame' is relative to the video. Convert it to
                % global frame number
                this.video.endFrame.left = endVideoAtFrame + ...
                    this.totFramesInPreviousVideos.left(this.endingVideo);
                this.video.endFrame.right =  this.getSyncedFrame(this.video.endFrame.left);
                
            end
            this.logStatus(sprintf('Left video will stop at frame #%.0f', this.video.endFrame.left));
            this.logStatus(sprintf('Right video will stop at frame #%.0f', this.video.endFrame.right));

            %% Define new frame step based on new frame rate
            this.video.originalFrameRate = leftVideoProps.frameRate;

            if(isnan(this.video.frameRate))
                this.video.frameRate = this.video.originalFrameRate;
            end

            this.video.actualFrameStep = ceil(this.video.originalFrameRate/this.video.frameRate);
            this.video.actualFrameRate = this.video.originalFrameRate/this.video.actualFrameStep;
            if(this.video.actualFrameRate ~= this.video.frameRate)
                this.logStatus(sprintf('New frame rate switched to %.2f from %.2f FPS', ...
                    this.video.actualFrameRate, this.video.frameRate));
            end
            this.logStatus(sprintf('Frame step set to %d', this.video.actualFrameStep));

            %% Define frame indexes to be used in the loop
            % frame indexes for each set to pick
            this.frIdx.left = this.video.startFrame.left:this.video.actualFrameStep:this.video.endFrame.left;
            this.numberOfFrames.toProcess = length(this.frIdx.left);
            
            %% Export settings
            this = this.exportSettings();

            %% Loop
            this = this.process();
            
            %% Save remaining tracks in system
            this.logStatus('Saving leftover tracks at the end of program');
            this = this.saveData();
            
            %% Done
            this.logStatus('Tracking ended');
            this.releaseSystem();
        end
    end
    
    methods(Access = private)
        % general
        this = initSystem(this);
        [] = logStatus(this, message, print);
        
        % read data
        this = countVideoFrames(this);
        this = readStereoFrames(this, kSubL, kSubR);
        
        this = process(this);
        
        % detection
        this = detectParticles(this);
        this = predictNewParticleLocations(this);
        this = assignDetectionsToCurrentTracks(this);
        this = updateAssignedTracks(this);
        this = createNewTracks(this);
        this = updateUnassignedTracks(this);
        
        % stereo triangulation
        this = trianguateParticles(this);
        this = estimateParticleLengths(this);
        
        % data handling
        this = exportSettings(this);
        this = updateSystem(this, trackIdx, data);
        this = markLostTracks(this);
        this = cleanUp(this);
        this = autoSave(this);
        this = saveData(this);
        syncedFrame = getSyncedFrame(this, leftFrame);
        
        [] = displayTracks(this);
        this = releaseSystem(this);
        if(~this.noGUI)
            this = progressWindow(this);
        end
    end
    
    methods(Static)
        [videoObject, videoProps] = readVideoFile(videoFile);
        fileList = loadFiles(pathToScan, videoExt);
        [] = createTrackFile(fileName);
        [assignment, cost] = munkres(costMatrix);
        str = formatDuration(durationInSecs);
    end
    
end

%% Parameter validation
function [stereoCalibrationFile, leftCameraPath, rightCameraPath, ...
    videoLagFile, mexopencvPath, blobDetectionSettings, trackDetectionSettings, ...
    kalmanSettings, matchParticlesSettings, showVideoPlayers, rotateLeftFrame, ...
    rotateRightFrame, enableLogging, frameRate, startingVideo, startingTime, ...
    endingVideo, endingTime, numberOfTrainingFrames, transformFrames, autoSaveEvery, ...
    maxTracks, videoFileExtension, maxTrackFileSize, noGUI] = validateAndParseInputs(varargin)

    % Validate and parse inputs
    narginchk(9, 37);
    
    parser = inputParser;
    parser.CaseSensitive = false;

    parser.addRequired('stereoCalibrationFile', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('leftCameraPath', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('rightCameraPath', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('videoLagFile', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('mexopencvPath', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('blobDetectionSettings', @(x)validateattributes(x, {'struct'}, {'nonempty'}));
    parser.addRequired('trackDetectionSettings', @(x)validateattributes(x, {'struct'}, {'nonempty'}));
    parser.addRequired('kalmanSettings', @(x)validateattributes(x, {'struct'}, {'nonempty'}));
    parser.addRequired('matchParticlesSettings', @(x)validateattributes(x, {'struct'}, {'nonempty'}));
        
    parser.addParameter('videoFileExtension', 'MP4', @(x)validateattributes(x, {'char'}, {}));
    parser.addParameter('maxTracks', 400, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('rotateLeftFrame', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('rotateRightFrame', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('showVideoPlayers', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('enableLogging', true, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('frameRate', NaN, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('startingVideo', 1, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('startingTime', 0, @(x)validateattributes(x, {'double'}, {'nonempty', '>=', 0}));
    parser.addParameter('endingVideo', NaN, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('endingTime', NaN, @(x)validateattributes(x, {'double'}, {'nonempty', '>=', 0}));
    parser.addParameter('numberOfTrainingFrames', 150, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('transformFrames', [], @(x)validateattributes(x, {'function_handle'}, {'nonempty'}));
    parser.addParameter('autoSaveEvery', 10, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar', '>', 0}));
    parser.addParameter('maxTrackFileSize', 300, @(x)validateattributes(x, {'double'}, {'nonempty', '>', 0}));
    parser.addParameter('noGUI', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    
    parser.parse(varargin{:});

    stereoCalibrationFile = parser.Results.stereoCalibrationFile;
    leftCameraPath = parser.Results.leftCameraPath;
    rightCameraPath = parser.Results.rightCameraPath;
    videoLagFile = parser.Results.videoLagFile;
    mexopencvPath = parser.Results.mexopencvPath;
    blobDetectionSettings = parser.Results.blobDetectionSettings;
    trackDetectionSettings = parser.Results.trackDetectionSettings;
    kalmanSettings = parser.Results.kalmanSettings;
    matchParticlesSettings = parser.Results.matchParticlesSettings;
    
    videoFileExtension = parser.Results.videoFileExtension;
    rotateLeftFrame = parser.Results.rotateLeftFrame;
    rotateRightFrame = parser.Results.rotateRightFrame;
    showVideoPlayers = parser.Results.showVideoPlayers;
    enableLogging = parser.Results.enableLogging;
    frameRate = parser.Results.frameRate;
    startingTime = parser.Results.startingTime;
    startingVideo = parser.Results.startingVideo;
    endingTime = parser.Results.endingTime;
    endingVideo = parser.Results.endingVideo;
    numberOfTrainingFrames = parser.Results.numberOfTrainingFrames;
    transformFrames = parser.Results.transformFrames;
    autoSaveEvery = parser.Results.autoSaveEvery;       
    maxTracks = parser.Results.maxTracks; 
    maxTrackFileSize = parser.Results.maxTrackFileSize;
    noGUI = parser.Results.noGUI;      
end

