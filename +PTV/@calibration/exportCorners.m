function [] = exportCorners(this, workspaceFile)
%EXPORTCORNERS Exports checkerboards corners to file

    % Save only the information from the corners detection alghoritm
    corners.imagesLeftAll = this.imagesLeftAll;
    corners.imagesRightAll = this.imagesRightAll;
    corners.imagesRightAllPlus = this.imagesRightAllPlus;
    corners.imagesRightAllMinus = this.imagesRightAllMinus;
    corners.fileNamesAll = this.fileNamesAll;
    corners.imagePointsLeft = this.imagePointsLeft;
    corners.imagePointsRight = this.imagePointsRight; 
    corners.imagePointsRightPlus = this.imagePointsRightPlus;
    corners.imagePointsRightMinus = this.imagePointsRightMinus;
    corners.boardSize = this.boardSize;
    corners.imagesUsed = this.imagesUsed;
    corners.imagesUsedL = this.imagesUsedL;
    corners.imagesUsedR = this.imagesUsedR;
    corners.imagesUsedRP = this.imagesUsedRP;
    corners.imagesUsedRM = this.imagesUsedRM;
    corners.imageSize = this.imageSize;
    corners.totalFrames = this.totalFrames;
    corners.worldPoints = this.worldPoints;
    corners.FramesPath = this.FramesPath;
    corners.SquareSize = this.SquareSize;
    corners.Name = this.Name;

    save(workspaceFile, 'corners');
    fprintf('>> Corners saved in ''%s''\n', workspaceFile);
end

