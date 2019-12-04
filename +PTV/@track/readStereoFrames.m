function [this] = readStereoFrames(this, kSubL, kSubR)
%SETFRAMENUMBER returns the specified frames from both cameras.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    this.step.isLeftFrameValid = true;
    this.step.isRightFrameValid = true;

    % use -1 otherwise when the video is read, the frame advances to
    % frameIdx+1
    this.video.left.set('PosFrames', kSubL-1);
    this.video.right.set('PosFrames', kSubR-1);
    
    this.step.leftFrame = this.video.left.read();
    this.step.rightFrame = this.video.right.read();
    
    if(isempty(this.step.leftFrame))    
        this.step.isLeftFrameValid = false;
    end
    
    if(isempty(this.step.rightFrame))    
        this.step.isRightFrameValid = false;
    end
    
    % Rotate frames if needed
    if(this.rotateLeftFrame)
        this.step.leftFrame = imrotate(this.step.leftFrame, 180);
    end

    if(this.rotateRightFrame)
        this.step.rightFrame = imrotate(this.step.rightFrame, 180);
    end
end

