classdef parSyncVideos
%SYNCVIDEOS determines the video delay between two sets of video files
%based on the analysis of the audio signals. Usage:
%
%  % path to folder or to single video
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
%      videoSet1      - Complete path to the folder containing the 1st set 
%                       of video files or path to a video
%      videoSet2      - Complete path to the folder containing the 2nd set
%                       of video files or path to a video
%      frameRate      - The video frame rate
%      totalVideos    - The total processed videos
%      framesSet1     - The number of frames in each video files from 1st set
%      framesSet2     - The number of frames in each video files from 2nd set
%      totalFramesCamera1      - The total frames in 1st set
%      totalFramesCamera2      - The total frames in 2nd set
%      totalAudioSamples       - Total audio samples
%      lag            - The lag output table with the following variables
%               * time: time from left video
%               * F1: synced frame from left video
%               * F2:  synced frame from right video
%               * audioStart: first audio sample index used for correlation
%               * audioEnd: last audio sample index used for correlation
%               * D: audio delay
%               * L: video delay
%               * L_tilde: rounded video delay
%               * tau: L_tilde-L
%      lagMessage     - Information message about lag (i.e. which video is
%                       advanced or delayed)
%      startLeftVideo  - Struct array containing information about frame
%                        and timestamp when left video should start to be
%                        in sync with the right video
%      startRightVideo - Struct array containing information about frame
%                        and timestamp when right video should start to be
%                        in sync with the left video
%
%   obj = PTV.syncVideos(...) provides the following public methods:
%
%      toStruct       - Convert class properties to a structure variable
%      interp         - In case 'frameStep' is not set to 1, interpolate 
%                       linearly the 'lag' table data so that the frame
%                       step for F1 is 1. Setting 'frameStep' to 1 may take
%                       a long time to sync the videos. The method updates
%                       this.lag with the new interpolated table.
%      save           - Save the lag data to a MAT file to be used in the 
%                       track algorithm. Specify the output file name as input
%                       of the method.
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>


    properties (GetAccess = public, SetAccess = private)
        % complete path to the folder containing the 1st set of video files
        videoSet1
        
        % complete path to the folder containing the 2nd set of video files
        videoSet2
        
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
        
        % number of audio samples to consider in the lag evaluation
        audioWindowSize
        
        % lag output table
        lag
        
        % message about lag
        lagMessage
        
        % first synced frame of right video with left video
        startRightVideo
        
        % first synced frame of left video with right video
        startLeftVideo
    end
    
    properties (GetAccess = private, SetAccess = public)
        % path to the MEX files of openCV
        mexopencvPath
        
        % Extension of the video files
        videoFileExtension
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
        
        % total audio samples to process
        totalAudioSamples
        
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
        
        % audio frame rate
        audioSamplingFrequency
        
        % constant lag assumed during tracking
        constantVideoLag
        
        % table header in this.lag
        lagHeader
        
        % for interpolation (syncVideos.interp()) save original table
        lagRaw
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % obj = syncVideos();
        function this = parSyncVideos(varargin)            
            [this.videoSet1, this.videoSet2, this.mexopencvPath, ...
                this.videoFileExtension, this.frameStep, this.audioWindowSize] = ...
                    validateAndParseInputs(varargin{:}); 

            this.lagHeader = {'time', 'F1', 'F2', 'D', 'L', 'L_tilde', 'tau'};
            addpath(this.mexopencvPath);

            if(contains(this.videoSet1, this.videoFileExtension))
                this.fileList1{1}.fullFile = this.videoSet1;
                this.fileList2{1}.fullFile = this.videoSet2;
                
                [fPath, fName] = fileparts(this.videoSet1);
                this.fileList1{1}.fileName = sprintf('%s.%s', fName, this.videoFileExtension);
                this.videoSet1 = fPath;
                
                [fPath, fName] = fileparts(this.videoSet2);
                this.fileList2{1}.fileName = sprintf('%s.%s', fName, this.videoFileExtension);
                this.videoSet2 = fPath;
            else
                this.fileList1 = this.loadFiles(this.videoSet1, this.videoFileExtension);
                this.fileList2 = this.loadFiles(this.videoSet2, this.videoFileExtension);
            end

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
            this.totalSamples = min([this.totalFramesCamera1 this.totalFramesCamera2]);

            %% Collect audio data (not optimised)
            a1 = fullfile(this.videoSet1, 'audioData.mat');
            a2 = fullfile(this.videoSet2, 'audioData.mat');
            if(~exist(a1, 'file') || ~exist(a2, 'file'))
                this.audio1 = [];
                this.audio2 = [];
                audioChannel = 1; % use 1st track in stereo
                timeTaken = 25;
                f = waitbar(0, 'Please wait...');
                for v=1:this.totalVideos
                    tic;
                    leftTime = (this.totalVideos-v+1)*timeTaken;
                    waitbar(v/this.totalVideos, f, ...
                        sprintf('Collecting audio tracks from video %d/%d - Left ~%.2f secs', ...
                        v, this.totalVideos, leftTime));
                    audioTmp1 = audioread(this.fileList1{v}.fullFile);
                    audioTmp2 = audioread(this.fileList2{v}.fullFile);

                    this.audio1 = [this.audio1; audioTmp1(:, audioChannel)];
                    this.audio2 = [this.audio2; audioTmp2(:, audioChannel)];
                    timeTaken = toc; 
                end
                % Export files
                audioTrack1 = this.audio1;
                save(fullfile(this.videoSet1, 'audioData.mat'), 'audioTrack1');
                audioTrack2 = this.audio2;
                save(fullfile(this.videoSet2, 'audioData.mat'), 'audioTrack2');

                close(f);
            else
                fprintf('>> Loading audio tracks from file\n');
                tmp = load(a1);
                this.audio1 = tmp.audioTrack1;
                
                tmp = load(a2);
                this.audio2 = tmp.audioTrack2;
            end
            
            this.totalAudioSamples = min([length(this.audio1) length(this.audio2)]);
            this.audioSamplingFrequency = 48*10^3;

            %% Find delay for video frames
            h = waitbar(0, 'Please wait...');
            Q = parallel.pool.DataQueue;
            listener = Q.afterEach(@nUpdateWaitbar);

            %% Init
            p = 1; % processed sample
            N = floor(this.totalSamples/this.frameStep);
            convRatio = 1/this.frameRate*this.audioSamplingFrequency;
            frameRate = this.frameRate;
            
            K = 1:N;
            % frame number
            FPrime = (K-1)*this.frameStep + 1;
            % audio indexes from frame number
            iStart = floor(FPrime/this.frameRate*this.audioSamplingFrequency);
            iEnd = iStart - 1 + this.audioWindowSize;
                
            % remove data exceeding audiot track length (usually for last
            % frame)
            I = iEnd > this.totalAudioSamples;
            iStart = iStart(~I);
            iEnd = iEnd(~I);
            K = K(~I);
            FPrime = FPrime(~I);
            N = length(K);
            
            % output variables
            D = NaN(N, 1);
            L = D; L_tilde = D; tau = D; F1 = D; F2 = D; lagTime = D;

            % Split audio track with cells. Each subtrack starts at each
            % frame (every this.frameStep video frames) with length this.audioWindowSize
            CAudio1 = arrayfun(@(i1, i2) this.audio1(i1:i2), iStart, iEnd, 'UniformOutput', false);
            CAudio2 = arrayfun(@(i1, i2) this.audio2(i1:i2), iStart, iEnd, 'UniformOutput', false);

            parpool(2);
            parfor k=K
                %% Get audio track range
                % tv = f/fv; A = fa/tv = f*fa/fv = f*48*10^3/48 = f*10^3;
                % round                
                Q.send(k);
                
                % Delay in audio samples
                D(k) = finddelay(CAudio2{k}, CAudio1{k}); 
                
                % Delay in the video frames
                L(k) = D(k)/convRatio;
                
                % Time
                lagTime(k) = FPrime(k)/frameRate;
                
                % with GoPcros L_tilde is always constant. With Olympus
                % Tough cameras, this may not be the case, due to the time 
                % jump created by the camera reaches when the 4GB limit 
                % on the video file is reached; when the new file is
                % created, Tough cameras introduce a larger lag than
                % the GoPros and L_tilde is not constant. To avoid error in
                % the tracking it is important to use the rounded L.
                L_tilde(k) = round(L(k));
                tau(k) = L_tilde(k) - L(k);
                
                if(D(k) > 0)
                    % Left video is advanced
                    % FPrime = 1; L_tilde(1) = 47; F1(1) = L_tilde + FPrime - 1 = 47 + 1 -1 = 47;
                    % F2(1)= F1(1) - L_tilde(1) + 1 = 47 - 47 + 1 = 1;
                    F1(k) = L_tilde(k) + FPrime(k) - 1;
                    F2(k) = F1(k) - L_tilde(k) + 1;
                else
                    % Left video is delayed
                    % FPrime = 1; L_tilde(1) = -47; F1(1) = FPrime = 1; 
                    % F2 (1) = F1(1) - L_tilde(1) - 1 = 1 + 47 - 1 = 47;
                    F1(k) = FPrime(k);
                    F2(k) = F1(k) - L_tilde(k) - 1;
                end
            end
            
            delete(listener);
            delete(gcp('nocreate'));
            
            this.lag = table(lagTime, F1, F2, D, L, L_tilde, tau, ...
                'VariableNames', this.lagHeader);
            
            function nUpdateWaitbar(~)
                waitbar(p/N, h, sprintf('Computing lag %d/%d items (%.1f%%)', ...
                    p, N, p/N*100));
                p = p + 1;
            end
        end
    
        % Convert class properties to a structure variable.
        function s = toStruct(this)
            str = fieldnames(this);
            for f=1:length(str)
                name = str{f};
                s.(name) = this.(name);
            end
        end
        
        function this = interp(this)
            % linear interpolation
            vector = this.lag.F1(1):this.lag.F1(end);
            L_tilde = NaN(length(vector), 1);
            L_tilde(1:this.frameStep:end) = this.lag.L_tilde;

            this.lagRaw = this.lag;
            this.lag = table(...
                interp1(this.lag.F1, this.lag.time, vector)', ...
                vector', ...
                interp1(this.lag.F1, this.lag.F2, vector)', ...
                interp1(this.lag.F1, this.lag.D, vector)', ...
                interp1(this.lag.F1, this.lag.L, vector)', ...
                fillmissing(L_tilde, 'previous'), ...
                interp1(this.lag.F1, this.lag.tau, vector)', ...
                'VariableNames', this.lagHeader([1:3 6:end]) ...
            );
        end
        
        function save(this, file)
            out = this.toStruct();
            save(file, '-struct', 'out');
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
