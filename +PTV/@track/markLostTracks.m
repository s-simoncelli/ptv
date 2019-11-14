function [this] = markLostTracks(this)
%MARKLOSTTRACKS marks tracks that have been invisible for too many consecutive
% frames.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    if(~isempty(this.step.tracks))
        % Compute the fraction of the track's age for which it was visible.
        ages = this.step.tracks.age;
        totalVisibleCounts = this.step.tracks.totalVisibleCount;
        consecutiveInvisibleCount = this.step.tracks.consecutiveInvisibleCount;
        visibility = totalVisibleCounts ./ ages;

        % Find the rows for the lost tracks
        s = this.trackDetectionSettings;
        rows = find((ages >= s.ageMin &  ages < s.ageMax & ...
            visibility < s.visibilityRatio) | ...
            consecutiveInvisibleCount >= s.invisibleForTooLong);
        
        if(~isempty(rows))
            % Delete track from the step object so that the Kalman filter
            % stops tracking the track
            this.step.tracks.lost(rows) = true;
        end

        this.logStatus(sprintf('Step #%d - Flagged %d/%d tracks as lost', ...
            this.step.counter, length(rows), height(this.step.tracks)), false);
    end
end
