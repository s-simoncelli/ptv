function [this] = updateUnassignedTracks(this)
%UPDATEUNASSIGNEDTRACKS marks the unassigned tracks as invisible for the
% current frame, and updates counters and centroids.
% The following track data are updated:
%
%   - age: incremented
%   - consecutiveInvisibleCount: incremented
%   - currentLeftparticleId: already set to NaN by predictNewParticleLocations
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    
    row = this.step.unassignedTracks;
    
    this.step.tracks.age(row) = this.step.tracks.age(row) + 1;

    this.step.tracks.totalInvisibleCount(row) = ...
        this.step.tracks.totalInvisibleCount(row) + 1;

    this.step.tracks.consecutiveInvisibleCount(row) = ...
        this.step.tracks.consecutiveInvisibleCount(row) + 1;
    
    timeTaken = toc;
    this.logStatus(sprintf('Step #%d - Updating unassigned tracks took %.3f seconds', ...
        this.step.counter, timeTaken), false);
end