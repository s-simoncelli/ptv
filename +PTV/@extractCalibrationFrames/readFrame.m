function [frame, isFrameValid] = readFrame(video, frameNumber)
%READFRAME Reads a video frame using openCV based on its index.
%
%  USAGE:  
%   frame = readFrame(video, frameNumber)
%
%  INPUT:
%    video         -  openCV video object               [obj]
%    frameNumber   -  Index of frame                    [double]
%
%  OUTPUT:
%    frame         -  RGB frame                        [matrix]
%    isFrameValid  -  Whether the frame is valid        [bool]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    if(~isa(video, 'cv.VideoCapture'))
        error('video must be a cv.VideoCapture object');
    end
    
    isFrameValid = true;

    % use frameNumber-1 otherwise when the video is read, the frame advances to
    % frameNumber+1 and the wrong frame is returned. This is because
    % cv.VideoCapture.grab grabs the next frame
    if(frameNumber ~= 1)
        frameNumber = frameNumber-1;
    end
    video.set('PosFrames', frameNumber);
    
    frame = video.read();
    if(isempty(frame))    
        isFrameValid = false;
        warning('Frame %d is invalid', frameNumber);        
    end
end

