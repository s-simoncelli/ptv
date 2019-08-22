classdef syncVideos
%SYNCVIDEOS determines the video delay between two sets of video files
%based on the analysis of the audio signals. Usage:
%
%  videoSet1 = '/path/to/files/in/first/set';
%  videoSet2 = '/path/to/files/in/second/set';
%  mexopencvPath = '/path/to/opencv/mex/files';
%
%  obj = PTV.syncVideos(videoSet1, videoSet2, mexopencvPath);
%  obj = PTV.syncVideos(..., 'audioWindowSize', 48000*50);
%  obj = PTV.syncVideos(..., 'frameStep', 300);
%
%
%  obj = PTV.syncVideos(..., Name, Value) specifies additional
%    name-value pairs described below:
%
%   'videoFileExtension'    Extension of the video files 
%
%                           Default: 'MP4'
%
%   'frameStep'             Step to use for the video frames. The delay
%                           will be estimated every 'frameStep' frames.
%
%                           Default: 100
%
%   'audioWindowSize'       Length of the window (as number of audio samples)
%                           to use when performing the auto-correlation
%                           of the two audio signals. This must include
%                           the time instant of the delay. If one camera
%                           was started after 1 min from the other one,
%                           set this larger than 48000*60.
%
%                           Default: 48000*60
%   
%
%   obj = PTV.syncVideos(...) returns a track object containing the following 
%   public properties:
%
%      videoSet1      - Complete path to the folder containing the 1st set of video files
%      videoSet2      - Complete path to the folder containing the 2nd set of video files
%      frameRate      - The video frame rate
%      totalVideos    - The total processed videos
%      framesSet1     - The number of frames in each video files from 1st set
%      framesSet2     - The number of frames in each video files from 2nd set
%      totalFramesCamera1      - The total frames in 1st set
%      totalFramesCamera2      - The total frames in 2nd set
%      audioSamplingFrequency  - The video frame rate
%      lag            - The lag output table with D, L, L_tilde and Tau
%      lagMessage     - The message about lag
%      lagTracking    - Struct array used by the tracking alghoritm
%        
%
%   obj = PTV.syncVideos(...) provides the following public methods:
%
%      toStruct       - Convert class properties to a structure variable
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>


    properties (GetAccess = public, SetAccess = private)
        % complete path to the folder containing the 1st set of video files
        videoSet1
        
        % complete path to the folder containing the 2nd set of video files
        videoSet2
        
        % path to the MEX files of openCV
        mexopencvPath
        
        % Extension of the video files
        videoFileExtension
        
        % video frame rate
        frameRate
        
        % total processed videos
        totalVideos
        
        % frames in each video files from 1st set
        framesSet1
        
        % frames in each video files from 2nd set
        framesSet2
        
        % total frames in 1st set
        totalFramesCamera1
        
        % total frames in 2nd set
        totalFramesCamera2
        
        % frame step to use in assessing the lag
        frameStep
        
        % audio frame rate
        audioSamplingFrequency
        
        % number of audio samples to consider in the lag evaluation
        audioWindowSize
        
        % lag output table
        lag
        
        % message about lag
        lagMessage
    end
    
    properties (Access = private)
        % vide files in 1st set
        fileList1
        
        % vide files in 2nd set
        fileList2
        
        % total number of frames to process
        totalSamples
        
        % vector of frames to process
        frames
        
        % time vector
        time
        
        % vector of audio samples to process
        audioSamples
        
        % time vector for audio
        audioTime
        
        % full audio tracks from 1st set
        audio1
        
        % full audio tracks from 2nd set
        audio2
        
        % subsample of full audio tracks from 1st set
        audio1Sample
        
        % subsample of full audio tracks from 2nd set
        audio2Sample
        
        % shifted subsample of full audio tracks from 1st set
        audio1SampleShifted
        
        % shifted subsample of full audio tracks from 2nd set
        audio2SampleShifted
        
        % constant lag assumed during tracking
        constantVideoLag
        
        % struct array for tracking
        lagTracking
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % obj = syncVideos();
        function this = syncVideos(varargin)            
            [this.videoSet1, this.videoSet2, this.mexopencvPath, ...
                this.videoFileExtension, this.frameStep, this.audioWindowSize] = ...
                    validateAndParseInputs(varargin{:}); 

            addpath(this.mexopencvPath);

            this.fileList1 = this.loadFiles(this.videoSet1, this.videoFileExtension);
            this.fileList2 = this.loadFiles(this.videoSet2, this.videoFileExtension);
             
            if(isempty(this.fileList1) || isempty(this.fileList2))
                error('Cannot file files in ''videoSet1'' or ''videoSet2''');
            end
            
            %% Collect total video frames
            this.totalVideos = length(this.fileList1);
      
            this.framesSet1 = NaN(1, this.totalVideos);
            this.framesSet2 = this.framesSet1;
            for v=1:this.totalVideos
                videoObject = cv.VideoCapture(this.fileList1{v}.fullFile);
                this.framesSet1(v) = videoObject.FrameCount;

                videoObject = cv.VideoCapture(this.fileList2{v}.fullFile);
                this.framesSet2(v) = videoObject.FrameCount;

                if(v == 1)
                    % with NTSC format the frame rate may not be an integer
                    this.frameRate = round(videoObject.FPS);
                end
            end

            this.totalFramesCamera1 = sum(this.framesSet1);
            this.totalFramesCamera2 = sum(this.framesSet2);

            %% Get frames to process
            totalSamples = min([this.totalFramesCamera1 this.totalFramesCamera2]);
            this.frames = 1:this.frameStep:totalSamples;
            this.totalSamples = length(this.frames);

            %% Collect audio data
            this.audio1 = [];
            this.audio2 = [];
            audioChannel = 1; % use 1st track in stereo
            timeTaken = 25;
            f = waitbar(0, 'Please wait...');
            for v=1:this.totalVideos
                tic;
                leftTime = (this.totalVideos-v+1)*timeTaken;
                waitbar((v-1)/this.totalVideos, f, ...
                    sprintf('Collecting audio tracks from video %d/%d - Left ~%.2f secs', ...
                    v, this.totalVideos, leftTime));
                audioTmp1 = audioread(this.fileList1{v}.fullFile);
                audioTmp2 = audioread(this.fileList2{v}.fullFile);

                this.audio1 = [this.audio1; audioTmp1(:, audioChannel)];
                this.audio2 = [this.audio2; audioTmp2(:, audioChannel)];
                timeTaken = toc; 
            end
            close(f);
            this.audioSamples = 1:min([length(this.audio1) length(this.audio2)]);
            this.audioSamplingFrequency = 48*10^3;

            %% General lag info 
            range = 1:this.audioWindowSize;
            this.audio1Sample = this.audio1(range);
            this.audio2Sample = this.audio2(range);

            [this.audio2SampleShifted, this.audio1SampleShifted, delay] = ...
                alignsignals(this.audio2Sample, this.audio1Sample);
    
            delay = delay + 1; % next point is the correct one
            audioTimeDelay = delay/this.audioSamplingFrequency; % to secs
            
            % video is sampled at a lower rate than audio, this introduces a small sync 
            % error. Get the closest previous or next frame to reduce this by rounding
            this.constantVideoLag.rawFrames = audioTimeDelay*this.frameRate;
            this.constantVideoLag.frames = round(this.constantVideoLag.rawFrames);
            this.constantVideoLag.time = this.constantVideoLag.frames/this.frameRate;
   
            this.lagTracking = struct('startRightVideo', [], 'startLeftVideo', []);
            if(delay > 0)
                this.lagMessage = sprintf('Left video is advanced of %.3f secs (%d frames). Cut it at %.3f secs.', ...
                    this.constantVideoLag.time, this.constantVideoLag.frames, this.constantVideoLag.time);

                % chop left video during tracking
                this.lagTracking.startRightVideo.time = 0;
                this.lagTracking.startRightVideo.frame = 1;

                this.lagTracking.startLeftVideo.time = this.constantVideoLag.time;
                this.lagTracking.startLeftVideo.frame = this.constantVideoLag.frames;

            else
                this.lagMessage = sprintf('Right video is advanced of %.3f secs (%d frames). Cut it at %.3f secs.', ...
                    -this.constantVideoLag.time, -this.constantVideoLag.frames, -this.constantVideoLag.time);

                % chop right video during tracking
                this.lagTracking.startRightVideo.time = -this.constantVideoLag.time;
                this.lagTracking.startRightVideo.frame = -this.constantVideoLag.frames;

                this.lagTracking.startLeftVideo.time = 0;
                this.lagTracking.startLeftVideo.frame = 1;
            end
            tmp = strsplit(this.lagMessage, ' Cut');
            fprintf('>> %s\n', tmp{1});
            
            %% Plot aligned signals from 1:this.audioWindowSize
            this.plotAudioSummary();

            %% Find delay for each frame in this.frames
            this.lag = [];
            k = 1; % if step ~= 1, k ~= f
            w = waitbar(0, 'Please wait...');
            timeTaken = 0;
            for ff=1:this.totalSamples
                tic;
                leftTime = (this.totalSamples-ff)*timeTaken;
                f = this.frames(ff);
                waitbar(ff/this.totalSamples, w, sprintf('Getting delay for frame %d/%d (%.1f%%) - Left %.2f mins',...
                    f, this.frames(end), ff/this.totalSamples*100, minutes(seconds(leftTime))));

                % tv = f/fv; A = fa/tv = f*fa/fv = f*48*10^3/48 = f*10^3;
                iStart = f*this.audioSamplingFrequency/this.frameRate;
                iEnd = iStart+this.audioWindowSize-1;
                
                if(iEnd > this.audioSamples(end))
                    % continue if the for the last sample the size is at
                    % least half the audioSamplingFrequency length
                    if(iStart - this.audioSamples(end) > this.audioSamplingFrequency/2)
                        iEnd = this.audioSamples(end);
                    else
                        break;
                    end
                end
                range = iStart:iEnd;
                tmp = finddelay(this.audio2(range), this.audio1(range));       
                this.lag(k).videoFrame = f;
                this.lag(k).time = f/this.frameRate; 

                this.lag(k).D = tmp; % delay in audio frmaes
                this.lag(k).L = tmp/this.audioSamplingFrequency*this.frameRate;

                % keep this constant. In the post-processing phase, the
                % Eqs. envolving Tau are written using the initial delay
                this.lag(k).L_tilde = this.constantVideoLag.frames;
                % this.lag(k).L_tilde = round(this.lag(k).L);
                this.lag(k).tau = this.lag(k).L_tilde - this.lag(k).L;
                k = k + 1;
                
                timeTaken = nanmean([timeTaken toc]); 
            end
            close(w);

            this.lag = struct2table(this.lag);
        end
        
        % Convert class properties to a structure variable.
        function s = toStruct(this)
            str = fieldnames(this);
            for f=1:length(str)
                name = str{f};
                s.(name) = this.(name);
            end
        end
    end
     
    methods(Access = private)
       [] = plotAudioSummary(this);
    end
    
    methods(Static)
       fileList = loadFiles(pathToScan, videoExt);
    end
    
end

%% Parameter validation
function [videoSet1, videoSet2, mexopencvPath, videoFileExtension, ...
    frameStep, audioWindowSize] = validateAndParseInputs(varargin)
    % Validate and parse inputs
    narginchk(1, 9);
    
    parser = inputParser;
    parser.CaseSensitive = false;    

    parser.addRequired('videoSet1', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('videoSet2', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('mexopencvPath', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    
    parser.addParameter('videoFileExtension', 'MP4', @(x)validateattributes(x, {'char'}, {}));
    parser.addParameter('frameStep', 100, @(x)validateattributes(x, {'numeric'}, ...
        {'real', 'scalar', 'integer', 'nonnegative', 'nonzero', '>=', 1}));
    parser.addParameter('audioWindowSize', 48000*60, @(x)validateattributes(x, {'numeric'}, ...
        {'real', 'scalar', 'integer', 'nonnegative', 'nonzero', '>=', 1}));
    
    parser.parse(varargin{:});

    videoSet1 = parser.Results.videoSet1;
    videoSet2 = parser.Results.videoSet2;
    mexopencvPath = parser.Results.mexopencvPath;
    
    videoFileExtension = parser.Results.videoFileExtension;
    frameStep = parser.Results.frameStep; 
    audioWindowSize = parser.Results.audioWindowSize;
end

