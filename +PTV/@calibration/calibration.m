classdef calibration
%CALIBRATION Calibrate stereo camera system using the
%vision toolbox provided by MATLAB. Usage:
%
%   pathToFrames = '/path/to/images';
%   squreSize = 30; % mm
%
%   obj = calibration(pathToFrames, squreSize);
%   obj = calibration(..., 'Name', 'stereo_cal');
%   obj = calibration(..., 'Exclude', [1 3 5]);
%   obj = calibration(..., 'SaveSummary', false);
%   obj = calibration(..., 'CheckFrameNumber', 14);
%
%  PTV.calibration() requires the following parameters:
%
%   1) Path of the frames extracted with PTV.extractCalibrationFrames.
%   2) Size of the chequerboard squares in mm.
%
%   obj = calibration(..., Name, Value) specifies additional
%    name-value pairs described below:
%
%   'name'                  Name of the calibration.
%
%                           Default: 'cal'
%
%   'exclude'               Frame IDs to exclude from the calibration set. For 
%                           example to exclude images 'f1' and 'f4', use [1
%                           4]. This is useful to exclude frames with high
%                           reprojection errors.
%
%                           Default: []
%
%   'saveSummary'           Save plots with calibration results.
%
%                           Default: true
%
%   'checkFrameNumber'      Frame number to use to verify the calibration (i.e
%                           to compute the disparity and reconstruct the 3D
%                           scene). You can also verify the calibration using a
%                           frame pair not belonging to the calibration set
%                           by calling the 'check' method.
%
%                           Default: first frame included in the calibration 
%                           set. The set includes frames with detected
%                           checkerboard corners and includes frames that
%                           have not been exluded with the 'Exclude'
%                           setting.
%
%   'disparityBlockSize':   Width of each square block whose pixels 
%                           are used for comparison between the images. 
%
%                           Default: 15. Max: 255. Min: 5.
%
%   'disparityMax'          Maximum value of disparity. Run the calibration
%                           at least once to measure the maximum distance
%                           using the imtool from the stereo anaglyph.
%
%                           Default: 64. 
%
%   'disparityContrastThreshold'   Acceptable range of contrast values.
%                                  Increasing this parameter results in
%                                  fewer pixels being marked as unreliable. 
%
%                                  Default: 0.5. Max: 1. Min: 0. 
%
%   'disparityUniquenessThreshold'  Minimum value of uniqueness. Increasing 
%                                   this parameter results in the function 
%                                   marking more pixels unreliable. When the 
%                                   uniqueness value for a pixel is low, the 
%                                   disparity computed for it is less reliable.
%
%                                  Default: 15.
%
%   obj = calibration.calibration(...) returns a calibration
%     object containing the output of the calibration. 
%
%  calibration properties:
%
%      Frames data
%      ------------------------------------------------------
%      imagesLeftAll  - Path to files from left camera
%      imagesRightAll - Path to files from right camera
%      fileNamesAll   - File names in the path
%      fileNames      - File names in the calibration set
%
%      Corner-detection output
%      ------------------------------------------------------
%      imagePointsLeft   - Detected points in frames from left cameras. See detectCheckerboardPoints
%      imagePointsRight  - Detected points in frames from right cameras.
%                          These points have been fixed to ensure frame
%                          synchronisation.
%      imagePoints   - Pattern points used in the calibration.
%      worldPoints   - Real world points of checkerboard. See generateCheckerboardPoints
%      boardSize     - Number of rows and columns in checkerboard. See detectCheckerboardPoints
%      imagesUsed    - Frames where the pattern was detected. See detectCheckerboardPoints
%      imageSize     - Size of the frame in pixels
%      totalFrames   - Total number of valid and non-excluded frames used in
%                       the calibration set. 
%
%      Calibration output
%      ------------------------------------------------------
%      stereoParams       - Calibration parameters. See stereoParameters
%      pairsUsed          - Frames used in the calibration. See estimateCameraParameters
%      estimationErrors   - Calibration errors. See estimateCameraParameters
%      rectificationError - Rectification errors in each frame.
%      epilines           - Epipolar lines for each frame. See epipolarLine
%
%      Verification output
%      ------------------------------------------------------
%      imageSizeRect          - Size of rectified frames in pixels.
%      disparityMap           - Disparity map for 'CheckFrameNumber'
%      validDisparityMap      - Valid values of disparity map for 'CheckFrameNumber'
%      invalidDisparityCount  - Number of invalid pixels in the disparity map
%      points3D               - World coordinates (metres) of the points in
%                               the 3D scene
%      invalidXYZCount        - Number of invalid world points in the 3D scene
%      ptCloud                - points3D as pointCloud object. See pointCloud
%
%  calibration methods:
%
%      plotErrors           - Plot reprojection and rectification histograms.
%      plotPatternLocations - Plot 3D location of checkerboards.
%      plotCameraModel      - Plot the camera models (accounting for radial and
%                             tangential distortions) and the relative position 
%                             of the two cameras.
%      plotSummary          - Run the 3 above methods together.
%      plot3DScene          - Plot the 3D scene of 'CheckFrameNumber' frame.
%      plotDiscardedFrames  - Plot frames where the checkerboard corners were 
%                             not fully detected.
%      plotExcludedFrames   - Check which frames were excluded with the 'Exclude' option.
%      check                - Check that the calibration works by correctly
%                             estimating the disparity map and reproducing
%                             the 3D scene for a provided frame pair.
%      compareRectifiedChequerboards - Compare rectified frames containing the 
%                                      chequerboards used in the calibration.
%                                       Chequer edges should be row-aligned 
%                                       according to epipolar geometry.
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    properties (GetAccess = public, SetAccess = private)
        % Path to files from left camera
        imagesLeftAll
        
        % Path to files from right camera
        imagesRightAll
        
        % Path to + files from right camera
        imagesRightAllPlus
        
        % Path to - files from right camera
        imagesRightAllMinus
        
        % File names in the path
        fileNamesAll
        
        % File names in the calibration set
        fileNames
        
        % Detected points in frames from left camera
        imagePointsLeft

        % Detected points in frames from right camera
        imagePointsRight

        % Detected points from left cameras and fixed points from right camera
        imagePoints
        
        % Number of rows and columns in checkerboard
        boardSize
        
        % Size of the frame in pixels
        imageSize
        
        % Total number of valid and non-excluded frames used in the calibration set
        totalFrames
        
        % Real world points of checkerboard
        worldPoints
        
        % Calibration parameters
        stereoParams
        
        % Frames used in the calibration
        pairsUsed
        
        % Calibration errors
        estimationErrors
        
        % Rectification errors
        rectificationError
        
        % Epipolar lines
        epilines
        
        % Disparity map for 'CheckFrameNumber'
        disparityMap
        
        % Valid values of disparity map for 'CheckFrameNumber'
        validDisparityMap
        
        % Number of invalid pixels in the disparity map
        invalidDisparityCount
        
        % Number of invalid world points in the 3D scen
        invalidXYZCount
        
        % Size of rectified frames
        imageSizeRect
        
        % points3D as pointCloud object
        ptCloud
        
        % World coordinates (metres) of the points from 'CheckFrameNumber'
        points3D

        % Frame intersection where the pattern was detected
        imagesUsed
    end


    properties (GetAccess = private, SetAccess = private)
        % Frames from the left camera frames where the pattern was detected.
        imagesUsedL
    
        % Frames from the right camera frames where the pattern was detected.
        imagesUsedR

        % Frames + from the right camera frames where the pattern was detected.
        imagesUsedRP

        % Frames - from the right camera frames where the pattern was detected.
        imagesUsedRM

        % Data from PTV.syncVideos
        lagData

        % Path to data from PTV.syncVideos or PTV.parSyncVideos
        lagParamsFile
        
        % Save plots with calibration results
        saveSummary

        % Detected points in frames from right camera (+ frames)
        imagePointsRightPlus

        % Detected points in frames from right camera (- frames)
        imagePointsRightMinus
    end
    
    properties (Access = public)
        % Path where the frames are
        framesPath
        
        % Size of the checkeboard square in mm
        squareSize
        
        % Name of the calibration
        name
        
        % Frame IDs to exclude from the calibration set
        exclude
        
        % Frame number to use to verify the calibration 
        checkFrameNumber
        
        % Maximum value of disparity
        disparityMax
        
        % Width of each square block for the disparity calculation
        disparityBlockSize
        
        % Acceptable range of contrast values for the disparity calculation
        disparityContrastThreshold
        
        % Minimum value of uniqueness
        disparityUniquenessThreshold
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % obj = calibration(pathToFrames, 30);
        % obj = calibration(..., 'Name', stereo_cal);
        % obj = calibration(..., 'Exclude', [1 3 5]);
        % obj = calibration(..., 'SaveSummary', false);
        % obj = calibration(..., 'CheckFrameNumber', int8(14));
        % obj = calibration(..., 'DisparityConfig', struct('method', 'SemiGlobal'));
        function this = calibration(varargin)            
            [this.framesPath, this.squareSize, this.lagParamsFile, this.name, this.exclude, ...
                this.saveSummary, this.checkFrameNumber, this.disparityBlockSize, ...
                this.disparityContrastThreshold, this.disparityUniquenessThreshold, ...
                this.disparityMax] = validateAndParseInputs(varargin{:}); 

            if(~exist(this.lagParamsFile, 'file'))
                error('File ''%s'' does not exist', this.lagParamsFile);
            end
            this.lagData = load(this.lagParamsFile);

            % workspace names
            pointsBaseFileName = sprintf('%s_corners.mat', this.name);
            pointsFullName = fullfile(this.framesPath, pointsBaseFileName);
    
            % workspace names
            calibrationBaseFileName = sprintf('%s_data.mat', this.name);
            calibrationFullName = fullfile(this.framesPath, calibrationBaseFileName);
 
            if(~exist(pointsFullName, 'file'))                
                this = loadImagePairs(this);
                fprintf('>> Found %d image pairs\n', length(this.fileNamesAll));
                
                if(length(this.fileNames) < 10)
                    warning('calibration:notEnoughtFrames', ...
                        ['You need at least 10 image pairs to properly ' ...
                        'calibrate the cameras']);
                end
                
                this = detectCorners(this);
                this.exportCorners(pointsFullName);
            else
                fprintf('>> Loading checkerboard corners from ''%s''\n', pointsBaseFileName);
                this = this.importCorners(pointsFullName);
                fprintf('>> Found %d pairs\n', length(this.fileNamesAll));
            end

            flag = find(this.imagesUsed == 0);
            count = length(flag);
            str = '';
            for i=1:count
                str = sprintf('%s#%d, ', str, flag(i));
            end
            str = str(1:end-2);
            if(count)
                fprintf('>> Cannot find corners in %d pairs: %s\n', count, str);
            end

            %% Remove images and points where the patter was not detected
            this.imagesLeftAll = this.imagesLeftAll(this.imagesUsed);
            this.imagesRightAll = this.imagesRightAll(this.imagesUsed);
            this.imagesRightAllPlus = this.imagesRightAllPlus(this.imagesUsed);
            this.imagesRightAllMinus = this.imagesRightAllMinus(this.imagesUsed);
            this.fileNames = this.fileNamesAll(this.imagesUsed);


            % frames in which the patter was detected may not matched
            % between cameras. Recreate the matrixes so that they have the
            % same sizes as this.totalFrames.
            totalCorners = prod(this.boardSize-1);
            tmp = this.imagePointsLeft;
            this.imagePointsLeft = NaN(totalCorners, 2, this.totalFrames);
            this.imagePointsLeft(:, :, this.imagesUsedL) = tmp;

            tmp = this.imagePointsRight;
            this.imagePointsRight = NaN(totalCorners, 2, this.totalFrames);
            this.imagePointsRight(:, :, this.imagesUsedR) = tmp;

            tmp = this.imagePointsRightPlus;
            this.imagePointsRightPlus = NaN(totalCorners, 2, this.totalFrames);
            this.imagePointsRightPlus(:, :, this.imagesUsedRP) = tmp;

            tmp = this.imagePointsRightMinus;
            this.imagePointsRightMinus = NaN(totalCorners, 2, this.totalFrames);
            this.imagePointsRightMinus(:, :, this.imagesUsedRM) = tmp;

            % remove data to get the intersections where pattern was found
            % in all frames (left, right, right + and right -) at the same
            % time
            this.imagePointsLeft = this.imagePointsLeft(:, :, this.imagesUsed);
            this.imagePointsRight = this.imagePointsRight(:, :, this.imagesUsed);
            this.imagePointsRightPlus = this.imagePointsRightPlus(:, :, this.imagesUsed);
            this.imagePointsRightMinus = this.imagePointsRightMinus(:, :, this.imagesUsed);

            % Exclude files
            fprintf('>> Excluding %d pairs\n', length(this.exclude));
            this = this.excludeFrames();
            
            this.totalFrames = size(this.imagePointsLeft, 3);
            if(this.totalFrames < 10)
                warning('calibration:notEnoughtFrames', ...
                    ['Found %d valid pairs. You need at least 10 to calibrate ' ...
                    'the cameras properly'], this.totalFrames);
            end

            %% Fix coordinates for points in right cameras
            this = this.fixRightCoordinates();

            % build matrix for stereo system 
            % M-by-2-by-numPairs-by-2 array of [x, y] points.
            this.imagePoints(:, :, :, 1) = this.imagePointsLeft;
            this.imagePoints(:, :, :, 2) = this.imagePointsRight;

            %% Calibration
            fprintf('>> Calibrating with %d pairs\n', this.totalFrames);
            [this.stereoParams, this.pairsUsed, this.estimationErrors] = ...
                estimateCameraParameters(this.imagePoints, this.worldPoints, ...
                'EstimateSkew', true, 'EstimateTangentialDistortion', true, ...
                'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'millimeters', ...
                'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
                'ImageSize', this.imageSize);

            
            if(this.stereoParams.MeanReprojectionError > 1)
                warning('calibration:reprojectionError', ...
                    ['The mean reprojection error is high (%.2fpx). Try removing ' ...
                    'some frames or positioning the pattern with different 3D ' ...
                    'orientations and cover all parts of the field of view'], ...
                    this.stereoParams.MeanReprojectionError);
            end

            this = this.computeRectificationError();
            
            if(this.rectificationError.mean > 1)
                warning('calibration:rectificationError', ...
                    ['The mean rectification error is high (%.2fpx). The ' ...
                    'estimation of the camera relative translation or rotation ' ...
                    'might be inaccurate. Try removing some frames and make sure ' ...
                    'to acquire the frames at the same time from both cameras.'], ...
                    this.rectificationError.mean);
            end
            
            % Plot summary
            fprintf('>> Plotting calibration summary\n');
            h = plotSummary(this);

            if(this.saveSummary)
                print(h.error, '-dpng', fullfile(this.framesPath, ...
                    sprintf('%s_errors.png', this.name)));
                print(h.patternLocation, '-dpng', fullfile(this.framesPath, ...
                    sprintf('%s_checkerboard_locations.png', this.name)));
                print(h.cameraModel, '-dpng', fullfile(this.framesPath, ...
                    sprintf('%s_camera_model.png', this.name)));
            end
            
            % Verify calibration
            fprintf('>> Verification\n');
            
            % find correct frame
            if(isempty(this.checkFrameNumber)) % get first available frame
                tmp = strsplit(this.fileNames{1}, 'f');
                frameIdx = tmp{end};
            else
                frameIdx = this.findFrameById();
            end

            leftFrame = imread(this.imagesLeftAll{frameIdx});
            rightFrame = imread(this.imagesRightAll{frameIdx});
            this = this.check(leftFrame, rightFrame);

            % Save
            calibrationData = this;
            save(calibrationFullName, 'calibrationData');
            
            fprintf('>> Done. Saved calibration parameters in ''%s''\n', calibrationBaseFileName);            
        end

        function s = toStruct(this)
        % Convert class properties to a structure variable.
            props = properties(this);
            for f=1:length(props)
                name = props{f};
                s.(name) = this.(name);
            end
        end

        function this = createFromStruct(this, data)
        % Load class properties from a structure variable.
            fieldNames = fields(data);
            for f=1:length(fieldNames)
                name = fieldNames{f};
                try
                    this.(name) = data.(name);
                catch
                    warning('calibration:fieldNotFound', ...
                        'Could not copy field %s', name);
                end
            end
        end
        
        % External method declaration
        h = plotSummary(this);
        h = plotErrors(this);
        h = plotPatternLocations(this);
        h = plotCameraModel(this);
        this = check(this, frameLeft, frameRight);
        player = plot3DScene(this);
        h = plotDiscardedFrames(this);
        h = plotExcludedFrames(this);
        [] = compareRectifiedChequerboards(this);
    end
    
    methods(Access = private)
        function frameIdx = findFrameById(this)
            % Find frame index in the provided set
            A = cellfun(@(i) strsplit(i, '_'), this.fileNames, 'UniformOutput', false);
            str = cellfun(@(i) i{1}, A, 'UniformOutput', false);
            I = strcmp(sprintf('f%d', this.checkFrameNumber), str);
            frameIdx = find(I == 1);
            if(isempty(frameIdx))
                error(['Pair %d not found for verification. This was either exclude with the ' ...
                    '''Exclude'' option or no pattern was found in it'], this.checkFrameNumber);
            end
        end
        
        % External method declaration
        this = loadImagePairs(this);
        this = detectCorners(this);
        [] = exportCorners(this, pointsFullName);
        this = computeRectificationError(this);
        this = importCorners(this, workspaceFile);
        this = excludeFrames(this);
    end
end

%% Parameter validation
function [framesPath, squareSize, lagParamsFile, name, exclude, saveSummary, checkFrameNumber, ...
    disparityBlockSize, disparityContrastThreshold, disparityUniquenessThreshold, ...
    disparityMax] = validateAndParseInputs(varargin)
    % Validate and parse inputs
    narginchk(7, 15);

    parser = inputParser;
    parser.CaseSensitive = false;

    parser.addRequired('framesPath', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addRequired('squareSize',  @(x)validateattributes(x,{'numeric'}, {'real','scalar', '>=', 1}));
    parser.addRequired('lagParamsFile',  @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addParameter('name', 'cal', @(x)validateattributes(x, {'char'}, {'nonempty'}));
    parser.addParameter('exclude', [], @(x)validateattributes(x, {'numeric'}, {'row', '>=', 0}));
    parser.addParameter('saveSummary', true, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
    parser.addParameter('checkFrameNumber',  [], @(x)validateattributes(x, {'numeric'}, {'real', 'scalar', 'integer'}));
    
    parser.addParameter('disparityBlockSize',  15, @(x)validateattributes(x, {'numeric'}, {'real', 'scalar', 'integer', 'odd', '>=', 5,'<=',255}));
    parser.addParameter('disparityContrastThreshold',  0.5, @(x)validateattributes(x, {'numeric'}, {'real', 'scalar', '>=',0,'<=',1}));
    parser.addParameter('disparityUniquenessThreshold',  15, @(x)validateattributes(x, {'numeric'}, {'real', 'scalar', '>=', 0}));
    parser.addParameter('disparityMax', 64, @(x)validateattributes(x, {'numeric'},{'real', 'scalar', '>=', 1}));
        
    parser.parse(varargin{:});

    framesPath = parser.Results.framesPath;
    squareSize = parser.Results.squareSize;
    lagParamsFile = parser.Results.lagParamsFile;

    name = parser.Results.name;
    exclude = parser.Results.exclude;
    saveSummary = parser.Results.saveSummary;
    checkFrameNumber = parser.Results.checkFrameNumber;
    disparityBlockSize = parser.Results.disparityBlockSize;
    disparityContrastThreshold = parser.Results.disparityContrastThreshold;
    disparityUniquenessThreshold = parser.Results.disparityUniquenessThreshold;
    disparityMax = parser.Results.disparityMax;
end

