function releaseSystem(this)
%RELEASESYSTEM Clear system objects.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    if(this.showVideoPlayers)
        release(this.video.maskPlayer);
        release(this.video.videoPlayer);
    end
    release(this.video.leftBlobAnalyser);
    release(this.video.rightBlobAnalyser);
    
    release(this.video.leftDetector);
    release(this.video.rightDetector);
    
    close(this.GUI.fig, 'force');
end

