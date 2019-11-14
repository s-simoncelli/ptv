function [] = util_plotDetectedParticles(logFile, trackFile, step)
%UTIL_PLOTDETECTEDPARTICLES Plot detected particles for the provided frame
%
% INPUT:
%  - logFile: path to log file                                    [string]
%  - logFile: path to track file                                  [string]
%  - step: step number for which to print the detected particles  [int]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    
    if(~(exist(trackFile, 'file')))
        error('Cannot find %s', trackFile);
    end 

   [leftVideos, rightVideos] = PTV.track.util_getProcessedVideos(logFile);
   
   data = readtable(trackFile);
   I = data.Step == step;
   
   if(all(I == 0))
       error('Cannot find step %d', step);
   end
   
   leftVideoNum = data.LeftVideo(I);
   leftVideoNum = leftVideoNum(1);
   rightVideoNum = data.RightVideo(I);
   rightVideoNum = rightVideoNum(1);
   
   leftFrameNum = data.LeftFrameID(I);
   leftFrameNum = leftFrameNum(1);
   rightFrameNum = data.RightFrameID(I);
   rightFrameNum = rightFrameNum(1);
   
   
end

