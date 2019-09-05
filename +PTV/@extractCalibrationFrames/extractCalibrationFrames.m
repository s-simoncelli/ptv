classdef extractCalibrationFrames
%EXTRACTCALIBRATIONFRAMES Extracts and saves frames for calibration. Usage:
%
%  leftVideo = '/path/to/video/from/left/camera';
%  rightVideo = '/path/to/video/from/right/camera';
%  mexopencvPath = '/path/to/opencv/mex/files';
%  % path to exported file from PTV.syncVideos 
%  lagParamsFile = '/path/to/delay/data';
%  % timestamp in seconds of the frames to extract from the left camera
%  timestamps = [1.22 3.322 5.32];
%  outPath = '/path/where/to/save/frames';
%
%  PTV.extractCalibrationFrames(leftVideo, rightVideo, ...
%         timestamps, lagParamsFile, mexOpencvPath, outPath);
%
%
%  PTV.extractCalibrationFrames() requires the following parameters:
%
%   1) Path to video recorded with left camera.
%   2) Path to video recorded with right camera.
%   3) Path to mexopencv library.
%   4) Lag data about video from left and right camera obtained 
%       from PTV.syncVideos or PTV.parSyncVideo
%   5) Timestamps in seconds of the frames from the left camera
%       to be extracted from the videos
%   6) Path where to save the frames.
%
%   lag = PTV.extractCalibrationFrames(..., Name, Value) specifies additional
%    name-value pairs described below:
%
%   'rotateLeftVideo'       Whether to rotate the left video of 180deg.
%
%                           Default to false.
%
%   'rotateRightVideo'      Whether to rotate the right video of 180deg.
%
%                           Default to false.
% 
% PTV.extractCalibrationFrames saves the frames into two sub-folders named 
% 'frames_left_camera' and 'frames_right_camera' in 'outPath'.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    properties (Access = public)
        % Path to video from left camera
        leftVideoFile
        
        % Path to video from right camera
        rightVideoFile
        
        % Extracting frames at the provided timestamps. Use the 
        % timestamp from the left video.
        getImagesAt
        
        % Path to MEX files for openCV
        mexopencvPath
        
        % Path where to export frames
        outPath

        % Path to data from PTV.syncVideos
        lagParamsFile
        
        % Whether to rotate the right video of 180deg
        rotateRightVideo
        
        % Whether to rotate the left video of 180deg
        rotateLeftVideo
    end
    
    properties (GetAccess = public, SetAccess = private)
        % Data from PTV.syncVideos
        lagData
    end
    
    methods
        function this = extractCalibrationFrames(varargin)            
            [this.leftVideoFile, this.rightVideoFile, this.getImagesAt, ...
               this.lagParamsFile, this.mexopencvPath, this.outPath, ...
               this.rotateRightVideo, this.rotateLeftVideo] = ...
                    validateAndParseInputs(varargin{:}); 

            if(~exist(this.lagParamsFile, 'file'))
                error('File ''%s'' does not exist', this.lagParamsFile);
            end
            
            this.lagData = load(this.lagParamsFile);
            fprintf('>> %s\n', this.lagData.lagMessage);
            
            %% Read videos first
            fprintf('>> Reading videos\n');
            [leftVideoObj, leftVideoProps] = this.readVideoFile(this.leftVideoFile);
            [rightVideoObj, ~] = this.readVideoFile(this.rightVideoFile);

            %% Show 1st frame for comparison
            t = this.getImagesAt(1);
            frameNumber.left = this.getFrameNumberFromTimestamp(leftVideoProps, t);
            frameNumber.right = this.getRightFrameIdx(frameNumber.left);

            leftFrame = this.readFrame(leftVideoObj, frameNumber.left);
            rightFrame = this.readFrame(rightVideoObj, frameNumber.right);

            if(this.rotateLeftVideo)
                leftFrame = imrotate(leftFrame, 180);
            end
            if(this.rotateRightVideo)
                rightFrame = imrotate(rightFrame, 180);
            end

            figure;
            im = cat(2, leftFrame, rightFrame);
            imshow(im);

            %% Get frames
            fprintf('>> Total frames to extract %d\n', length(this.getImagesAt));
            
            outPath1 = fullfile(this.outPath, 'frames_left_camera');
            outPath2 = fullfile(this.outPath, 'frames_right_camera');
            fprintf('>> Frames will be extracted in %s and %s\n', outPath1, outPath2);
            prompt = '>> Do you want to generate the frames? Y/N [N]: ';
            str = input(prompt, 's');
            if(strcmpi(str, 'y'))
                % Create directories
                if(~exist(outPath1, 'dir'))
                    mkdir(outPath1);
                end
                if(~exist(outPath2, 'dir'))
                    mkdir(outPath2);
                end

                fprintf('>> Starting frame extraction\n');
                f = waitbar(0, 'Please wait...');
                meanTime = 0;
                totalImages = length(this.getImagesAt);
                for imageNumber=1:totalImages
                    tic;

                    frac = imageNumber/length(this.getImagesAt);
                    timeLeft = minutes(seconds(meanTime*(totalImages-imageNumber)));
                    waitbar(frac, f, sprintf('Extracting frame %d/%d at %.3f secs (%d%%) - Left: %.2f mins', ...
                         imageNumber, length(this.getImagesAt), t, ...
                         round(frac*100), timeLeft));
                     
                    %% Left
                    t = this.getImagesAt(imageNumber);
                    frameNumber.left = this.getFrameNumberFromTimestamp(leftVideoProps, t);
                    [leftFrame, leftValid] = this.readFrame(leftVideoObj, frameNumber.left);
                    if(~leftValid)
                        warning('Left frame #%d is invalid. Skipped', frameNumber.left);
                        continue;
                    end
                    if(this.rotateLeftVideo)
                        leftFrame = imrotate(leftFrame, 180);
                    end
                    frameFileName = sprintf('f%d_%d.png', imageNumber, frameNumber.left);
                    imwrite(leftFrame, fullfile(outPath1, frameFileName), 'png');
                    
                    %% Right
                    frameNumber.right = this.getRightFrameIdx(frameNumber.left);
                    % extract more frames for coordinate interpolation
                    frameRight = frameNumber.right + [-1 0 1];
                    l = {'-', '', '+'};
                    for frx=1:length(frameRight)
                        currentFrame = frameRight(frx);
                        [rightFrame, rightValid] = this.readFrame(rightVideoObj, currentFrame);
                        if(~rightValid)
                            warning('Right frame #%d is invalid. Skipped', currentFrame);
                            continue;
                        end
                        if(this.rotateRightVideo)
                            rightFrame = imrotate(rightFrame, 180);
                        end
                        frameFileNameX = sprintf('f%d_%d%s.png', imageNumber, currentFrame, l{frx});
                        imwrite(rightFrame, fullfile(outPath2, frameFileNameX), 'png');
                    end
                    
                    meanTime = nanmean([meanTime; toc]);
                end
                
                fprintf('>> Extracted %d frames\n', imageNumber);
                close(f);
            else
                fprintf('>> Skipped\n');
            end
        end
    end
    
    methods(Access = private)
        [videoObject, videoProps] = readVideoFile(this, videoFile)
        rightFrameIdx = getRightFrameIdx(this, frameIdx);
    end
    
    methods(Static)
        [frame, isFrameValid] = readFrame(video, frameNumber);
        frameNumber = getFrameNumberFromTimestamp(videoProps, timestamp);
    end
end


%% Parameter validation
function [leftVideoFile, rightVideoFile, getImagesAt, lagParamsFile, ...
    mexopencvPath, outPath, rotateRightVideo, rotateLeftVideo] = validateAndParseInputs(varargin)
    % Validate and parse inputs
    narginchk(1, 10);

    parser = inputParser;
    parser.CaseSensitive = true;

    parser.addRequired('leftVideoFile', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('rightVideoFile', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('getImagesAt',  @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addRequired('lagParamsFile',  @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('mexopencvPath',  @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('outPath',  @(x)validateattributes(x, {'char'}, {'nonempty'}));
   
    parser.addParameter('rotateRightVideo', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('rotateLeftVideo', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
        
    parser.parse(varargin{:});

    leftVideoFile = parser.Results.leftVideoFile;
    rightVideoFile = parser.Results.rightVideoFile;
    getImagesAt = parser.Results.getImagesAt;
    mexopencvPath = parser.Results.mexopencvPath;
    outPath = parser.Results.outPath;
    lagParamsFile = parser.Results.lagParamsFile;
    
    rotateRightVideo = parser.Results.rotateRightVideo;
    rotateLeftVideo = parser.Results.rotateLeftVideo;
end


