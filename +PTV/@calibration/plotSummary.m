function h = plotSummary(this)
%Plot results of calibration.
%
%  OUTPUT:
%    h.error             - Plot of reprojection and epipolar errors   [Figure]
%    h.patternLocation   - Plot of pattern location                   [Figure]
%    h.cameraModel       - Plot of cameras model                      [Figure]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    % Reprojection errors
    h.error = this.plotErrors();
    
    % Pattern locations
    h.patternLocation = this.plotPatternLocations();

    % Cameras model
    h.cameraModel = this.plotCameraModel();
end

