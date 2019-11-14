function [this] = cleanUp(this)
%CLEANUP removes hidden tracks from this.step.tracks. These tracks have 
% already been exported into this.system
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    
    rows = this.step.tracks.lost == true;    
    this.step.tracks(rows, :) = [];
    
    this.logStatus(sprintf('Step #%d - Removing lost tracks took %.3f seconds', ...
        this.step.counter, toc), false);
end

