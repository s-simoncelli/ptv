function h = plotPatternLocations(this)
%PLOTPATTERNLOCATIONS Plots a 3D view of the checkerboard locations with
%respect to each camera.
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    h = figure; 
    showExtrinsics(this.stereoParams, 'CameraCentric');
end

