function [syncedFrame] = getSyncedFrame(this, leftFrame)
%SYNCFRAME Returns the corresponding synced frame from the right camera,
%given the frame index from the left camera

    I = find(this.lagSettings.lag.F1 == leftFrame);
    if(isempty(I))
        error('Cannot find right frame from left frame #%d', leftFrame);
    end
    syncedFrame = this.lagSettings.lag.F2(I);
end

