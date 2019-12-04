function [this] = countVideoFrames(this)
%COUNTVIDEOFRAMES Counts the frame in a video. 
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    this.logStatus('Counting total frames in concatenated and synced videos', false);
    this.numberOfFrames = struct(); % frame counter per video set
    for d=1:this.video.total
        % read video with open CV
        vL = this.video.leftVideos{d};
        videoObject = cv.VideoCapture(vL.fullFile);
        this.numberOfFrames.left(d) = videoObject.FrameCount;
        
        this.logStatus(sprintf('Left video #%d %s: %d total frames', d, vL.fileName, ...
            this.numberOfFrames.left(d)), false);

        vR = this.video.rightVideos{d};
        videoObject = cv.VideoCapture(vR.fullFile);
        this.numberOfFrames.right(d) = videoObject.FrameCount;
        
        this.logStatus(sprintf('Right video #%d %s: %d total frames', d, vR.fileName, ...
            this.numberOfFrames.right(d)), false);
    end

    % total frame counter
    this.numberOfFrames.totalLeft = sum(this.numberOfFrames.left);
    this.numberOfFrames.totalRight = sum(this.numberOfFrames.right);

    this.logStatus(sprintf('Set from left camera: %d total frames', ...
        this.numberOfFrames.totalLeft), false);
    this.logStatus(sprintf('Set from right camera: %d total frames', ...
        this.numberOfFrames.totalRight), false);
    
    % cumulative sum of frames
    this.totFramesInPreviousVideos.left = cumsum(this.numberOfFrames.left);
    this.totFramesInPreviousVideos.left = [0 this.totFramesInPreviousVideos.left];
    this.totFramesInPreviousVideos.right = cumsum(this.numberOfFrames.right);
    this.totFramesInPreviousVideos.right = [0 this.totFramesInPreviousVideos.right];
end

