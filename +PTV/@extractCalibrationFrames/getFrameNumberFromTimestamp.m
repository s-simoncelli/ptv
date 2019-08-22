function frameNumber = getFrameNumberFromTimestamp(videoProps, timestamp)
%READFRAME Returns the frame index based on the specified video timestamp.
%
%  USAGE:  
%   frameNumber = getFrameNumberFromTimestamp(videoProps, timestamp)
%
%  INPUT:
%    videoProps    -  Video properties from readVideoFile   [struct]
%    timestamp     -  Timestamp at which the frame should 
%                     be extracted                          [double]
%
%  OUTPUT:
%    frameNumber   -  The frame index                       [double]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    if(~isfield(videoProps, 'frameRate'))
        error('videoProps does not contain the frameRate field');
    end
    
    % Get the closest previous or next frame by rounding up or down
    % to reduce this error. Max error is 0.5 frames.
    frameNumber = round(timestamp*videoProps.frameRate);
end

