function [X, Y, Z] = rotationMatToDeg(rotMat)
%ROTATIONMATTODEG Converts the rotation matrix to angles (in degrees) along 
% the X (roll), Y (pitch) and Z (yaw) directions.
%
% REFERENCE: https://stackoverflow.com/questions/19202928/extract-euler-angles-from-3x3-rotation-matrix-resulted-in-camera-calibration-pro
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
  
    X  = atan2(rotMat(3, 2), rotMat(3, 3))* (180/pi);
    Y = asin(rotMat(3, 1)) * (180/pi);
    Z   = atan2(rotMat(2, 1), rotMat(1, 1)) * (180/pi);
    
end

