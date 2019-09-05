function rightFrameIdx = getRightFrameIdx(this, frameIdx)
%GETRIGHTFRAMEIDX Get frame number of the right video from the frame number of 
% the left video

    I = find(this.lagData.lag.F1 == frameIdx, 1, 'first');
    if(isempty(I))
        warning('Cannot find synced right frame for left frame #%d', frameIdx);     
        rightFrameIdx = [];
    else
        rightFrameIdx = this.lagData.lag.F2(I);
    end
    
end