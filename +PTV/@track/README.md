# Introduction

This MATLAB package tracks particles from a stereo rig. Type

    help PTV.track

or

    doc PTV.track

anytime in the MATLAB Command Window to recall the following documentation.

# Usage
```matlab
    obj = PTV.track(calibrationFile, leftCameraPath, rightCameraPath, ...
     videoLagParamsFile, mexopencvPath, blobDetectionSettings, trackDetectionSettings, ...
     kalmanSettings, matchParticlesSettings);
```

`PTV.track()` requires the following parameters:
  1)  **calibrationFile**: path to calibration file. This must be a `stereoParameters` object either 
      generated from `PTV.calibrate` package
  2) **leftCameraPath**: path to videos shot from the left camera
  3) **rightCameraPath**: path to videos shot from the right camera
  4) **videoLagFile**: path to lag data generated from the `syncVideos.save()` or `parSyncVideos.save()` methods in the PTV package 
  5) **mexopencvPathv**: path to mexopencv files
  6) **blobDetectionSettings**: Struct array with options for the blob detection. See `vision.BlobAnalysis` for the option explanation. Example: 

        ```matlab
            blobDetectionSettings = struct('minimumBackgroundRatio', 0.4, 'minimumBlobArea', 10, ...
             'maximumBlobArea', 200, 'maximumCount', 600);
        ```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If `minimumBlobArea` is too large, small particles close to the cameras or large and far-away particles may not be detected. If `minimumBlobArea` is instead too small, you might track background variations that are not particles, but small variations in ligth intensity in the background. If `maximumCount` is too small, some particles may not be tracked in some areas of the image. Make sure to detect as many particle as possible. Change these values based on the number of particles expected in the system.

7) **trackDetectionSettings**: struct array with options for track detection settings. Example: 

    ```matlab
        trackDetectionSettings = struct('visibilityRatio', 0.6, 'ageThreshold', 8, ...
            'invisibleForTooLong', 20);
        ```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A track is regarded as visible when a particle is associated to it. A tracks is considered lost or invisible when no particles are associated to it for too many consecutive frames. Lost tracks identify particles that exist the FOV and are not visible anymore, or particles that are not detected anymore by the blob analysis algorithm. A track is defined as lost when one of the following conditions occur:

 * the track age (defined as number of frames since the track was first detected) is between than `ageMin` and `ageMax` and their visibility (defined as the fraction of the track's age for which it was  visible) is less than `visibilityRatio`. This criterion identifies young tracks that have been invisible for too many frames. `ageMin` ensures not to remove tracks immediately. For example if age = 2 and the track was invisible for 1 frame, visibility would .5 and the track would be removed if visibilityRatio = 0.6.  In the example the number of non consecutive frames for which  the track was invisible is 0.6*8 ~ 5 frames.

  * the number of consecutive frames when the track was invisible is greater or equal to `invisibleForTooLong`. This helps to identify particles that left the system and whose track is not traceable anymore. 
        
8) **kalmanSettings**: struct array with options for the Kalman algorithm settings. See `configureKalmanFilter` for the option explanation. Example: 

    ```matlab 
        kalmanSettings = struct('costOfNonAssignment', 20, 'motionModel',  ...
            'ConstantVelocity', 'initialEstimateError', [200 50], ...
            'motionNoise', [30 25], 'measurementNoise', 20);              
    ```

     The `costOfNonAssignment` value should be tuned experimentally. A
     too low value increases the likelihood of creating a new track, and
     lead to track fragmentation. A too high threshold may result in a
     single track corresponding to a series of separate moving objects.

9) **matchParticlesSettings**: struct array with options for match particle algorithm. For the options see the `particleMatching` class in the PTV package.  Example:

    ```matlab
        matchParticlesSettings = struct('minScore', .8, 'maxAreaRatio', 1.1, ...
            'minAreaRatio', .9, 'subFramePadding', 15, 'searchingAreaPadding', 30);
    ```

`obj = PTV.track(..., 'PropertyName', PropertyValue)` specifies additional name-value pairs described below:

- **frameRate**:  down-sample the videos using a new frame rate instead of processing all the available frames. Default: []
- **startingVideo**:  number of video from left camera when to start processing the video set. Default: 1
- **startingTime**:  number of seconds from the `startingTime` video when to start processing the frames. Default: 0
- **endingVideo**:  number of video from left camera when to stop processing in the set. Default: 1
- **startingTime**:  number of seconds from the `endingVideo` video when to stop processing the frames. Default: 0
- **numberOfTrainingFrames**: number of frames to use for training the foreground algorithm. See `NumTrainingFrames` in vision.ForegroundDetector. Default: 100
- **rotateLeftFrame**: whether to rotate the left frame. Default: false
- **rotateRightFrame**: whether to rotate the right frame. Default: false
- **transformFrames**: function handle to transform frames. This function is called after rectifying the stereo frames to crop or deform them. The inputs and outputs of  this function are the left and right rectified frames as array. Default: []
- **showVideoPlayers**: show video players with tracks. This may increase the processing time of each frame depending on the number of tracks to plot. Default: false
- **enableLogging**: write log messages into a .log file. Default: true
- **autoSaveEvery**: auto save tracking data every `autoSaveEvery`  processed frames. Default: 10
- **maxTracks**:   maximum number of tracks to track. Once the system saturates, new discovered tracks are not added into the system anymore. New tracks will be added only when one more more track are marked as lost and removed from the system. Increasing this value, may increase the processing time, in particular in relation to the Hungarian alghoritm. Default: 400
- **videoFileExtension**: extension of the video files. Default: `MP4`

`obj = PTV.track(...)` returns a `track` object containing the following public properties:

- **trackFile**: path to saved tracks
- **logFile**: path to log file
- **numberOfFrames**: total number of frames in videos
- **unit**:  unit for 3D coordinates

`obj = PTV.calibration(...)` saves the track output every `autoSaveEvery` analysed frames in an ASCII file in the `logs` subfolder, where your videos are stored. When the file reaches 300 MiB a new result file is created. These files contain a table; each row contains data about a particle detected in the frame at a given time instant. The table columns are the following:

- **Step**: number of tracking step when particle was detected.
- **Global left frame**: cumulative number of frame from the left camera, when particle was detected.
- **Global right frame**: cumulative number of frame from the right camera, when particle was detected.
- **Time**: cumulative elapsed time from videos from the left camera, when particle was detected.
- **Left video**: number of video from the set of the left camera, when particle was detected.
- **Left frame ID**: number of frame relative to `Left video` from the left camera, when particle was detected.
- **Right video**: number of video from the set of the right camera, when particle was detected.
- **Right frame ID**: number of frame relative to `Right video` from the left camera, when particle was detected.
- **Track ID**: the detected particle is part of the track identified by this unique number.
- **Age**: particle age. See `trackDetectionSettings`.
- **TotalVisibleCount**: see `trackDetectionSettings`.
- **TotalInvisibleCount**: see `trackDetectionSettings`.
- **ConsecutiveInvisibleCount**: see `trackDetectionSettings`.
- **Estimated**: whether the particle position in px was estimated by the Kalman Filter. Position is estimated if the particle is not assigned toa track by the assignement algorithm.
- **Lost**: see `trackDetectionSettings`.
- **x**: horizontal position of the particle in the left frame in px.
- **y**: vertical position of the particle in the left frame in px.
- **Disparity**: particle disparity in px. This is NaN is not particle is matched.
- **Area**: particle area in px.
- **Major ax**: particle major axis in px.
- **Minor ax**: particle minor axis in px.
- **Area**: particle area in px.
- **Orientation**: particle orientation in deg.
- **Eccentricity**: particle eccentricity.
- **r2**: equivalent squared radius of particle in px.
- **Perimeter**: particle perimeter in px.
- **BB Width**: width of the bounding box in px.
- **BB Height**: height of the bounding box in px.
- **X**: particle X location. The unit depends on the unit used in the calibration, usually mm.
- **Y**: particle Y location.
- **Z**: particle Z location.
- **Length H**: particle horizontal length. The unit depends on the unit used in the calibration, usually mm.
- **Length V**: particle vertical length. The unit depends on the unit used in the calibration, usually mm.

In the `logs` subfolder the following files are also created:

- **info_*.log**: the log file contains info or warning messages during each step of the tracking. 
- **settings_*.yml**: this file contains all the parameters used in the tracking process.


 # Example
 ```matlab
    clc; clear; close all;
    % Import calibration package
    addpath('/path/to/this/package/ptv');

    % Import its classes
    import PTV.*

    %% Setting
    % calibration file from PTV.calibrate
    stereoCalibrationFile = '/path/to/calibration/file/stereo_cal_4.mat';

    % path to videos
    leftCameraPath = fullfile('/path/to/folder/with/videos/from/left/camera');
    rightCameraPath = fullfile('/path/to/folder/with/videos/from/right/camera'');

    % path to lag data from PTV.syncVideos or PTV.parSyncVideos
    videoLagParamsFile = fullfile(/path/to/lag/file/');

    % path to mexopencvPath
    mexopencvPath  = '/path/to/mexopencv';

    % blob detection settings
    blobDetectionSettings = struct('minimumBackgroundRatio', 0.7, ...
        'minimumBlobArea', 20, 'maximumBlobArea', 10^4, 'maximumCount', 1000);

    % track detection settings
    trackDetectionSettings = struct('visibilityRatio', 0.6, 'ageMin', 3, ...
        'ageMax', 5, 'invisibleForTooLong', 20);

    % Kalman algohritm settings
    kalmanSettings = struct('costOfNonAssignment', 15, 'motionModel', 'ConstantVelocity', ...
        'initialEstimateError', [200 50], 'motionNoise', [3 25], ...
        'measurementNoise', 5);

    % match particle alghoritm settings
     matchParticlesSettings = struct('minScore', .8, 'maxAreaRatio', 1.1, ...
         'minAreaRatio', .9, 'minDepth', 8*10, 'maxDepth', 32*10);

    % @deblur is the function handle in a file named deblur.m (see below)
    out = PTV.track(stereoCalibrationFile, leftCameraPath, rightCameraPath, ...
        videoLagParamsFile, mexopencvPath, blobDetectionSettings, trackDetectionSettings, ...
        kalmanSettings, matchParticlesSettings, 'enableLogging', true, ...
        'frameRate', 30, 'startingTime', 7*60+18, 'endingVideo', 4, ...
        'endingTime', 30,'transformFrames', @deBlur, ...
        'numberOfTrainingFrames', 100, 'autoSaveEvery', 2000, ...
        'showVideoPlayers', true, 'maxTracks', 800, 'videoFileExtension', ...
        'MOV');

    % Content of deblur.m
    function [leftFrameRect, rightFrameRect] = deBlur(leftFrameRect, rightFrameRect)    
        leftFrameRect = imsharpen(leftFrameRect, 'Radius', 10, 'Threshold', 0.1);
        rightFrameRect = imsharpen(rightFrameRect, 'Radius', 10, 'Threshold', 0.1);
    end
```