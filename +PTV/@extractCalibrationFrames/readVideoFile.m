function [videoObject, videoProps] = readVideoFile(this, videoFile)
%READVIDEOFILE Read video file and returns its properties.
%
%  INPUT:
%    mexopencvPath          - Path to the 'mexopencvPath' libs    [string]
%
%  OUTPUT:
%    videoObject             -  openCV object                     [obj]
%    videoProps.frameRate    -  Video frame rate                  [double]
%    videoProps.numFrames    -  Total number of frames            [double]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    % Path checks
    if(~exist(this.mexopencvPath, 'dir'))
        error('The provided path to mexopencv does not exist');
    end

    if(~exist(videoFile, 'file'))
        error('The provided video file does not exist');
    end
    
    addpath(this.mexopencvPath);
    
    % read video with open CV
    videoObject = cv.VideoCapture(videoFile);
    videoProps.numFrames = videoObject.FrameCount;
    % Ideal video frame rate would be 48/1001*1000, for a 48FPS video
    videoProps.frameRate = videoObject.FPS;
end