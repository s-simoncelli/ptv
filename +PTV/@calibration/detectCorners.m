function this = detectCorners(this)
%DETECTCORNERS Detect checkerboards in images
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    this.totalFrames = length(this.imagesLeftAll); 

    fprintf('>> Detecting checkerboard corners from frames from');
    fprintf(' left camera');
    [this.imagePointsLeft, this.boardSize, this.imagesUsedL] = ...
        detectCheckerboardPoints(this.imagesLeftAll);

    fprintf(', right camera');
    [this.imagePointsRight, ~, this.imagesUsedR] = ...
        detectCheckerboardPoints(this.imagesRightAll);
    fprintf(', right camera +');        
    [this.imagePointsRightPlus, ~, this.imagesUsedRP] = ...
        detectCheckerboardPoints(this.imagesRightAllPlus);
    fprintf(', right camera -\n'); 
    [this.imagePointsRightMinus, ~, this.imagesUsedRM] = ...
        detectCheckerboardPoints(this.imagesRightAllMinus);

    % get intersection of frames where chequerboard was found
    this.imagesUsed = this.imagesUsedL & this.imagesUsedR & ...
        this.imagesUsedRP & this.imagesUsedRM;
    
    % Generate world coordinates of the chequerboard keypoints. Each
    % pattern contains prod(this.boardSize-1) points
    this.worldPoints = generateCheckerboardPoints(this.boardSize, this.SquareSize);
    [mrows, ncols, ~] = size(imread(this.imagesLeftAll{1}));
    this.imageSize = [mrows ncols];
end