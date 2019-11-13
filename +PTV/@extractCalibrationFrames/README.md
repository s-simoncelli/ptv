# Introduction

This MATLAB package extracts synchronised video frames to be used in `PTV.calibration.` Type

    help PTV.extractCalibrationFrames

or

    doc PTV.extractCalibrationFrames

anytime in the MATLAB Command Window to recall the following documentation.

# Usage
 ```matlab
    leftVideo = '/path/to/video/from/left/camera';
    rightVideo = '/path/to/video/from/right/camera';
    mexopencvPath = '/path/to/opencv/mex/files';
    % path to exported file from PTV.syncVideos 
    lagParamsFile = '/path/to/delay/data';
    % timestamp in seconds of the frames to extract from the left camera
    timestamps = [1.22 3.322 5.32];
    outPath = '/path/where/to/save/frames';

    PTV.extractCalibrationFrames(leftVideo, rightVideo, ...
            timestamps, lagParamsFile, mexOpencvPath, outPath);
```

   `PTV.extractCalibrationFrames()` requires the following parameters:

   1) Path to video recorded with left camera.
   2) Path to video recorded with right camera.
   3) Path to mexopencv library.
   4) Lag data about video from left and right camera obtained  from `PTV.syncVideos` or `PTV.parSyncVideo`
   5) Timestamps in seconds of the frames from the left camera to be extracted from the videos
   6) Path where to save the frames.

`obj = PTV.extractCalibrationFrames(..., Name, Value)` specifies additional name-value pairs described below:

- **rotateLeftVideo** -  Whether to rotate the left video of 180deg. Default: false
- **rotateRightVideo** -   Whether to rotate the right video of 180deg. Default: false

The algorithm exports the specified frames from the left camera and the synced ones from the right camera. For each frame from the right camera, the previous and next frames are also extracted to correct the chequerboard coordinates during the calibration to ensure video synchronisation.

 # Example
 ```matlab
    clc; clear; close all;
    delete(findall(0,'type','figure','tag','TMWWaitbar'));

    addpath('/path/to/ptv/package');

    import PTV.*

    leftVideo = '/Volumes/stereo_cameras/calibration/GOPR0935.MP4';
    rightVideo = '/Volumes/stereo_cameras/calibration/GOPR0321.MP4';
    mexopencvPath  = '/Users/yourUser/Documents/MATLAB/mexopencv-d29007b';
    getImagesAt = [40.801 41.604 44.956 45.976 47.452 54.966 60.221 61.477];
    outPath = '/Volumes/stereo_cameras/calibration/';
    lagParamsFile = '/Volumes/calibrations/syncData.mat';

    %% Get lag data first
    if(~exist(lagParamsFile, 'file'))
        % Get lag every 10 frames
        obj = PTV.parSyncVideos(leftVideo, rightVideo, mexOpencvPath, 'frameStep', 10);

        % Interpolate the lag linearly
        data = obj.interp();
        
        % save sync data so that they can be used again
        data.save(lagParamsFile);
    end

    %% Extract frames
    PTV.extractCalibrationFrames(videoSet1, videoSet2, getImagesAt, lagParamsFile, ...
    mexOpencvPath, outPath);
```
