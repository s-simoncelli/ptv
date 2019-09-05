function this = loadImagePairs(this)
%LOADPAIRS Load frames from folder.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    %% Left frame
    framesLeftCameraPath = fullfile(this.FramesPath, 'frames_left_camera');
    this.fileNames = dir([framesLeftCameraPath '/f*.png']);
    if(isempty(this.fileNames))
        error('Cannot find any images in %s', framesLeftCameraPath);
    end

    [~, I] = PTV.sort_nat({this.fileNames.name}); % natural sorting
    this.fileNames = this.fileNames(I);
    for f=1:length(this.fileNames)
        this.imagesLeftAll{f} = fullfile(framesLeftCameraPath, this.fileNames(f).name);
    end
    
    this.fileNamesAll = strrep({this.fileNames.name}, '.png', '');
    
    %% Right frame. Split between synced frames and + / -
    framesRightCameraPath = fullfile(this.FramesPath, 'frames_right_camera');
    fileNamesRight = dir([framesRightCameraPath '/f*.png']);
    
    % natural sorting
    [~, I] = PTV.sort_nat({fileNamesRight.name}); 
    fileNamesRight = fileNamesRight(I);
    
    % get file name without + or -
    matches = cellfun(@(i) regexp(i,'^f(\d{1,2})_(\d*).png'), {fileNamesRight.name}, 'UniformOutput', false);
    matches = ~cellfun('isempty', matches);
    tmp = fileNamesRight(matches);
    for f=1:length(tmp)
        this.imagesRightAll{f} = fullfile(framesRightCameraPath, tmp(f).name);
    end
    
    % get file name with +
    matches = cellfun(@(i) regexp(i,'^f(\d{1,2})_(\d*)(+).png'), {fileNamesRight.name}, 'UniformOutput', false);
    matches = ~cellfun('isempty', matches);
    tmp = fileNamesRight(matches);
    for f=1:length(tmp)
        this.imagesRightAllPlus{f} = fullfile(framesRightCameraPath, tmp(f).name);
    end
    
    % get file name with -
    matches = cellfun(@(i) regexp(i,'^f(\d{1,2})_(\d*)(-).png'), {fileNamesRight.name}, 'UniformOutput', false);
    matches = ~cellfun('isempty', matches);
    tmp = fileNamesRight(matches);
    for f=1:length(tmp)
        this.imagesRightAllMinus{f} = fullfile(framesRightCameraPath, tmp(f).name);
    end
    
    total = length(this.fileNames);
    if(length(this.imagesRightAll) ~= total || length(this.imagesRightAllPlus) ~= total || ...
            length(this.imagesRightAllMinus) ~= total)
        error('The number of frames from the right camera does not match that of the left camera');
    end
end