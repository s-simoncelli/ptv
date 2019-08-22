function rightFrameIdx = getRightFrameIdx(this, frameIdx)
%GETRIGHTFRAMEIDX Get frame number of the right video from the frame number of 
% the left video

    I = find(this.lagData.lag.F1 >= frameIdx, 1, 'first');
    rightFrameIdx = this.lagData.lag.F2(I);
end