# Introduction

This MATLAB package performs the extraction of synchronised  video frames
to be used in PTV.calibration. Type

    help PTV.extractCalibrationFrames

or

    doc PTV.extractCalibrationFrames

anytime in the MATLAB Command Window to recall the following documentation.

# Usage
 ```matlab
    videoSet1 = '/path/to/files/in/first/set';
    videoSet2 = '/path/to/files/in/second/set';
    mexopencvPath = '/path/to/opencv/mex/files';
    % path to exported file from PTV.syncVideos 
    lagParamsFile = '/path/to/delay/data';
    % timestamp in seconds of the frames to extract from the left camera
    timestamps = [1.22 3.322 5.32];
    outPath = '/path/where/to/save/frames';

   PTV.extractCalibrationFrames(videoSet1, videoSet2, ...
            timestamps, lagParamsFile, mexOpencvPath, outPath);
```

`obj = PTV.extractCalibrationFrames(..., Name, Value)` specifies additional name-value pairs described below:

- **rotateLeftVideo** -  Whether to rotate the left video of 180deg. Default: false
- **rotateRightVideo** -   Whether to rotate the right video of 180deg.. Default: false

 # Example
 ```matlab
    clc; clear; close all;
    delete(findall(0,'type','figure','tag','TMWWaitbar'));

    addpath('../../');

    import PTV.*

    videoSet1 = '/Volumes/stereo_cameras/calibration/GOPR0935.MP4';
    videoSet2 = '/Volumes/stereo_cameras/calibration/GOPR0321.MP4';
    mexopencvPath  = '/Users/yourUser/Documents/MATLAB/mexopencv-d29007b';
    getImagesAt = [40.801 41.604 44.956 45.976 47.452 54.966 60.221 61.477];
    outPath = '/Volumes/stereo_cameras/calibration/';
    lagParamsFile = '/Volumes/calibrations/syncData.mat';

    %% Sync videos
    if(~exist(lagParamsFile, 'file'))
        % Get lag every 10 frames
        obj = PTV.syncVideos(videoSet1, videoSet2, mexOpencvPath, 'frameStep', 10);

        % Interpolate the lag linearly
        data = obj.toStruct();
        data.lag_raw = data.lag;

        % linear interpolation
        vector = data.lag.F1(1):data.lag.F1(end);
        data.lag = table(...
            interp1(data.lag.F1, data.lag.time, vector)', ...
            vector', ...
            interp1(data.lag.F1, data.lag.F2, vector)', ...
            interp1(data.lag.F1, data.lag.D, vector)', ...
            interp1(data.lag.F1, data.lag.L, vector)', ...
            interp1(data.lag.F1, data.lag.L_tilde, vector)', ...
            interp1(data.lag.F1, data.lag.tau, vector)', ...
            'VariableNames', {'time', 'F1', 'F2', 'D', 'L', 'L_tilde', 'tau'} ...
        );
        % save sync data so thay it may be used again
        save(lagParamsFile, '-struct', 'data');
    end

    %% Extract frames
    PTV.extractCalibrationFrames(videoSet1, videoSet2, ...
            getImagesAt, lagParamsFile, mexOpencvPath, outPath);
```
