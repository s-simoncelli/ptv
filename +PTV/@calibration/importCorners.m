function this = importCorners(this, workspaceFile)
%IMPORTCORNERS Imports checkerboards corners from file
%
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    a = load(workspaceFile);
    a = a.corners;

    this.imagesLeftAll = a.imagesLeftAll;
    this.imagesRightAll = a.imagesRightAll;
    this.imagesRightAllPlus = a.imagesRightAllPlus;
    this.imagesRightAllMinus = a.imagesRightAllMinus;
    this.fileNamesAll = a.fileNamesAll;
    this.imagePointsLeft = a.imagePointsLeft;
    this.imagePointsRight = a.imagePointsRight; 
    this.imagePointsRightPlus = a.imagePointsRightPlus;
    this.imagePointsRightMinus = a.imagePointsRightMinus;
    this.boardSize = a.boardSize;
    this.imagesUsed = a.imagesUsed;
    this.imagesUsedL = a.imagesUsedL;
    this.imagesUsedR = a.imagesUsedR;
    this.imagesUsedRP = a.imagesUsedRP;
    this.imagesUsedRM = a.imagesUsedRM;
    this.imageSize = a.imageSize;
    this.totalFrames = a.totalFrames;
    this.worldPoints = a.worldPoints;
    this.FramesPath = a.FramesPath;
    this.SquareSize = a.SquareSize;
    this.Name = a.Name;
end

