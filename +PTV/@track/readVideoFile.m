function [videoObject, videoProps] = readVideoFile(videoFile)
%READVIDEOFILE Read video file and returns its properties
%
%  INPUT:
%    videoFile       -  Path to video file                     [string]
%    mexopencvPath   -  Path to the 'mexopencvPath' libs       [string]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
%     if(~exist(this.mexopencvPath, 'dir'))
%         error('The provided path to mexopencv does not exist');
%     else
%         addpath(this.mexopencvPath, fullfile(this.mexopencvPath, 'opencv_contrib'));
%     end
    
    % read video with open CV
    videoObject = cv.VideoCapture(videoFile);
    
    videoProps.frameRate = videoObject.FPS;
    videoProps.numFrames = videoObject.FrameCount;
end