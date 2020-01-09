classdef particleMatching
%MATCHPARTICLE Matches similar particles between stereo frames. Usage:
%
%   obj = particleMatching(leftFrame, rightFrame, leftParticles, rightParticles);
%   obj = particleMatching(..., 'subFramePadding', 30);
%   obj = particleMatching(..., 'searchingAreaPadding', 10);
%   obj = particleMatching(..., 'minScore', 0.9);
%   obj = particleMatching(..., 'maxAreaRatio', 1.5);
%
%   'leftFrame' and 'rightFrame' must be of type 'uint8' (i.e. frames must
%   be loaded with imread or similar function). 'leftParticles' and 
%   'rightParticles' must be table with the following fields: 
%   'id', 'area', 'centroid' and 'bbox'.
%
%   obj = particleMatching(..., Name, Value) specifies additional
%   name-value pairs described below:
% 
%   'subFramePadding'       Padding to add to the particle in the left frame 
%                           for template matching. When the particle image 
%                           from the left frame is extracted, the image is
%                           padded to allow comparison with images of
%                           particlea within the searching area from the right
%                           frame. 
%
%                           Default: 15
%
%   'searchingAreaPadding'  Padding to add above and below the Y coordinate
%                           centroid of the particle in the left frame.
%                           This value affects the height of the searching
%                           area in the right frame. The larger the
%                           padding, the larger the area and more particles
%                           are selected as possible candidates for
%                           matching.
%
%                           Default: 30
%
%   'minScore'              Minium score for template matching to match
%                           particles. 
%
%                           Default: 0.8
%
%   'minScoreForMultipleMatches'  With mutiple matches, choose particle
%                                 whose score is largewr than 'minScoreForMultipleMatches'
%
%                           Default: 0.9
%
%
%   'maxAreaRatio'          Maximum ratio of areas between a particle in the 
%                           left frame and the candidates from the right
%                           frame. Particles in the right frame whose area
%                           ratio is above this value are not considered
%                           for matching. A value of 1.1 means that,
%                           particles with area 10% larger than that of the
%                           particle to be matched in the left frame, are
%                           neglected.
%
%                           Default: 1.1
%
%   'minAreaRatio'          Minimum ratio of areas between a particle in the 
%                           left frame and the candidates from the right
%                           frame. Particles in the right frame whose area
%                           ratio is below this value are not considered
%                           for matching. A value of 0.9 means that,
%                           particles with area 10% smaller than that of the
%                           particle to be matched in the left frame, are
%                           neglected.
%
%                           Default: 0.9
%
%   'debug'                 Export additional variables for debugging. 
%
%                           Default: false
%       
%   obj = PTV.particleMatching(...) returns a particleMatching
%     object containing the output of the matching algorithm. 
%
%  particleMatching properties:
%
%      Frames data
%      ------------------------------------------------------
%      count           - Information about the number of (un)matched particles
%      matchData       - Data containing the relation between particle IDs in
%                        the left and right frame. The table also contains
%                        data about the match score, the particle area
%                        ration and their disparity in px.
%      multipleMatches - Multiple matches between a particle in the left frame 
%                        and its candidate particles in the right frame.
%                        These matches are removed from matchData.
%                        Available when debug is set to true.
%      duplicatedMatches   - Multiple matches between a particle in the right 
%                            frame and particles in the left frame.
%                            Available when debug is set to true.
%      scoreData           - Scores all particles from left to right frame
%                            and from right to left frame.
%                            Available when debug is set to true.
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>


    properties (GetAccess = public, SetAccess = private)
       % path to calibration file. Must be a stereoParameters object
       stereoCalibrationFile
        
       % left frame in stereo pair
       leftFrame
       
       % right frame in stereo pair
       rightFrame
       
       % table for particles in left frame
       leftParticles
       
       % table for particles in right frame
       rightParticles
       
       % padding to add to particle in left frame for correlation
       subFramePadding
       
       % padding to add above and below the Y coordinate centroid of the
       % particle in the left frame (it defines the searching area)
       searchingAreaPadding
       
       % minium score for matching
       minScore
       
       minScoreForMultipleMatches
       
       % maximum ratio of areas between a particle in the left frame and
       % its candidates from the right frame
       maxAreaRatio
       
       % minimum ratio of areas between a particle in the left frame and
       % its candidates from the right frame
       minAreaRatio
            
       % export additional data for debugging
       debug
       
       % information about the number of (un)matched particles
       count
       
       % matching information
       matchData
       
       % multiple matches between particle in the left frame and candidate
       % particle in the right frame
       multipleMatches
       
       % multiple matches between particle in the right frame and particles
       % in the left frame
       duplicatedMatches
       
       % score between particles in both frames
       scoreData
       
       % stereo baseline, mm (i.e. camera distance)
       baseLine
       
       % focal length, px
       focalLength
       
       % minimum depth, mm
       minDepth
       
       % maximum depth, mm
       maxDepth
       
       % maximum disparity, px
       maxDisparity
       
       % minimum disparity, px
       minDisparity
       
       % size of the frames
       imageSize
       
       % total particles in the left frame
       totalLeftParticles
    end
    
    properties (Access = private)
       
    end
    
    methods
        %==================================================================
        % Constructor
        %==================================================================
        % obj = particleMatching(leftFrame, rightFrame, leftParticles, rightParticles);
        function this = particleMatching(varargin)            
            [this.leftFrame, this.rightFrame, this.leftParticles, this.rightParticles,  ...
                this.baseLine, this.focalLength, this.minDepth, this.maxDepth, ...
                this.subFramePadding, this.searchingAreaPadding, ...
                this.minScore, this.minScoreForMultipleMatches, this.maxAreaRatio, ...
                this.minAreaRatio, this.debug] = validateAndParseInputs(varargin{:}); 

            this = this.init();
            
            this = this.match();
            
            this = this.findDuplicates();

            % count particles with no match
            A = this.matchData.rightParticleId;
            this.count.noMatch = length(find(isnan(A)));
            
            % total particles with a match
            this.count.matched = length(find(~isnan(A)));
    
            if(this.debug)
                this = this.exportScoreRightToLeft();
                
                % table conversion
                this.duplicatedMatches = struct2table(this.duplicatedMatches);
                
                this.scoreData.rightToLeft = struct2table(this.scoreData.rightToLeft);
            end
        end
    end
    
    methods(Access = private)                
        % External method declaration
        this = init(this);
        this = match(this);
        this = findDuplicates(this);
        this = exportScoreRightToLeft(this);
    end
end

%% Parameter validation
function [leftFrame, rightFrame, leftParticles, rightParticles, ...
    baseLine, focalLength, minDepth, maxDepth, subFramePadding, searchingAreaPadding, ...
    minScore, minScoreForMultipleMatches, maxAreaRatio, minAreaRatio, debug] = validateAndParseInputs(varargin)

    % Validate and parse inputs
    narginchk(1, 26);
    
    parser = inputParser;
    parser.CaseSensitive = false;

    parser.addRequired('leftFrame', @(x)validateattributes(x, {'uint8'}, {'nonempty'}));
    parser.addRequired('rightFrame', @(x)validateattributes(x, {'uint8'}, {'nonempty'}));
    parser.addRequired('leftParticles', @(x)validateattributes(x, {'table'}, {'nonempty'}));
    parser.addRequired('rightParticles', @(x)validateattributes(x, {'table'}, {'nonempty'}));
    
    parser.addParameter('baseLine', NaN, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('focalLength', NaN, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('minDepth', NaN, @(x)validateattributes(x, {'double'}, {'nonempty', '>', 0}));
    parser.addParameter('maxDepth', NaN, @(x)validateattributes(x, {'double'}, {'nonempty', '>', 0}));    
    parser.addParameter('subFramePadding', 15, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar'}));
    parser.addParameter('searchingAreaPadding', 30, @(x)validateattributes(x, {'double'}, {'nonempty', 'scalar'}));
    parser.addParameter('minScore', .8, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('minScoreForMultipleMatches', .9, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('maxAreaRatio', 1.2, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('minAreaRatio', .8, @(x)validateattributes(x, {'double'}, {'nonempty'}));
    parser.addParameter('debug', false, @(x)validateattributes(x, {'logical'}, {'nonempty'}));
      
    parser.parse(varargin{:});

    leftFrame = parser.Results.leftFrame;
    rightFrame = parser.Results.rightFrame;
    leftParticles = parser.Results.leftParticles;
    rightParticles = parser.Results.rightParticles;
    
    baseLine = parser.Results.baseLine;
    focalLength = parser.Results.focalLength;
    minDepth = parser.Results.minDepth;
    maxDepth = parser.Results.maxDepth;
    subFramePadding = parser.Results.subFramePadding;
    searchingAreaPadding = parser.Results.searchingAreaPadding;
    minScore = parser.Results.minScore;
    minScoreForMultipleMatches = parser.Results.minScoreForMultipleMatches;
    maxAreaRatio = parser.Results.maxAreaRatio;
    minAreaRatio = parser.Results.minAreaRatio;
    debug = parser.Results.debug;
end

