function this = init(this)
%MATCH Initialises objects.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tmp = size(this.leftFrame);
    this.imageSize = tmp([2 1]);
                
    if(~isequal(size(this.leftFrame), size(this.rightFrame)))
        error('Stereo frames must have the same size');
    end

    if(this.minScoreForMultipleMatches < this.minScore)
        error('''minScoreForMultipleMatches'' must be larger than ''minScore''');
    end
   
    if(this.minDepth >= this.maxDepth)
        error('''minDepth'' must be less than ''maxDepth''');
    end
    
    this.count.noScore = 0;
    this.totalLeftParticles = height(this.leftParticles);
    
    this.matchData = table('Size', [this.totalLeftParticles 5], 'VariableTypes', ...
        {'single', 'single', 'single', 'single', 'single'}, 'VariableNames', ...
        {'leftParticleId', 'rightParticleId', 'score', 'areaRatio', 'disparity'});
         
    % convert frames from RGB to gray-scale
    this.leftFrame = rgb2gray(this.leftFrame);
    this.rightFrame = rgb2gray(this.rightFrame);
    
    % estimate the maximum size of the searching area from the minimum
    % depth. The Depth would be from the principal point (Z'=Z+f) but here
    % we assume that Z=Z' since we do not know the focal distance in mm
    % (i.e. the pixel size is not known); in any case f<<Z.
    % The depth is computed only when all the variables are provided
    % otherwise it remains of NaN class.
    this.maxDisparity = round(this.baseLine*this.focalLength/this.minDepth);
    if(this.maxDisparity >= this.imageSize(1))
        error(['The computed maximum disparity (%.2f px) is larger than ', ...
            'the image width (%d px). Try increasing ''minDepth'''], ...
            this.maxDisparity, this.imageSize(1));
    end

    this.minDisparity = round(this.baseLine*this.focalLength/this.maxDepth);
    
    if(this.debug)
        % data when a particle in the left frame has multiple matches with 
        % particles in the searching area in the right frame
        this.multipleMatches = table;

        % data when a particle in the right frame has multiple matches with
        % particles in the left frame
        this.duplicatedMatches = struct('rightParticleId', {[]}, 'leftParticleDuplicatedIds', {{}}, ...
            'leftParticleMatchedId', {[]});

        % correlation between a particle from left frame with those in the
        % searching area in the right frame
        this.scoreData.leftToRight = struct('leftParticleId', {[]}, 'data', {{}});

        % correlation between a particle from right frame with those matched in
        % the left frame
        this.scoreData.rightToLeft = struct('rightParticleId', {[]}, 'data', {{}});
    end
end

