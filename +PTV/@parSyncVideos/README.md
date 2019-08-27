# Introduction

This MATLAB package extracts the lag data between two non-synchronised video 
streams. Type

    help PTV.syncVideos

or

    doc PTV.syncVideos

anytime in the MATLAB Command Window to recall the following documentation.

# Usage
 ```matlab
    % path to folder or to single video
    pathToFrames = '/path/to/images';
    videoSet1 = '/path/to/files/in/first/set';
    videoSet2 = '/path/to/files/in/second/set';
    mexopencvPath = '/path/to/opencv/mex/files';

    obj = PTV.syncVideos(videoSet1, videoSet2, mexopencvPath);
    obj = PTV.syncVideos(..., 'audioWindowSize', 48000*50);
    obj = PTV.syncVideos(..., 'frameStep', 300);
```

`obj = PTV.syncVideos(..., Name, Value)` specifies additional name-value pairs described below:

- **videoFileExtension** -  Extension of the video files . Default: 'MP4'
- **frameStep** -      Step to use for the video frames. The delay will be estimated every 'frameStep' frames. Default: 100
- **audioWindowSize** -      Length of the window (as number of audio samples) to use when performing the auto-correlation of the two audio signals. This must include the time instant of the delay. If one camera was started after 1 min from the other one, set this larger than 48000\*60. Default: 48000\*60

`obj = PTV.syncVideos(...)` returns a *syncVideos* object containing the output of the lag estimation.

# syncVideos properties
 - **videoSet1**      - Complete path to the folder containing the 1st set of video files or path to a video
 - **videoSet2**      - Complete path to the folder containing the 2nd set of video files or path to a video
 - **frameRate**      - The video frame rate
 - **totalVideos**    - The total processed videos
 - **framesSet1**     - The number of frames in each video files from 1st set
 - **framesSet2**     - The number of frames in each video files from 2nd set
 - **totalFramesCamera1**      - The total frames in 1st set
 - **totalFramesCamera2**      - The total frames in 2nd set
 - **audioSamplingFrequency**  - The video frame rate
 - **totalAudioSamples**  - Total audio samples
 - **lag**            - The lag output table with the following variables
   - `time`: time from left video
   - `F1`: synced frame from left video
   - `F2`:  synced frame from right video
   - `audioStart`: first audio sample index used for correlation
   - `audioEnd:` last audio sample index used for correlation
   - `D`: audio delay
   - `L`: video delay
   - `L_tilde`: rounded video delay
   - `tau`: `L_tilde`-`l`
 - **lagMessage**     - The message about lag
 - **lagTracking**    - Struct array used by the tracking alghoritm

Once the audio tracks have been read, the program plots the first chunk of synchronised audio tracks:

![alt text](./audio_signals.png)

It then proceeds estimating the audio delay for the frames

![alt text](./getting_lag.png)

The output is stored in `obj.lag`.

 # Example
 ```matlab
    clc; clear; close all;
    delete(findall(0,'type','figure','tag','TMWWaitbar'));

    addpath('../../');

    import PTV.*

    videoSet1 = '/Volumes/stereo_cameras/lake/deployment_1/left/';
    videoSet2 = '/Volumes/stereo_cameras/lake/deployment_1/right/';
    mexopencvPath  = '/Users/yourUser/Documents/MATLAB/mexopencv-d29007b';

    obj = PTV.syncVideos(videoSet1, videoSet2, mexopencvPath, 'frameStep', 500);

    % Plot
    figure; 
    subplot(211); hold on;
    plot(obj.lag.time, obj.lag.L, 'k--');
    plot(obj.lag.time, obj.lag.L_tilde, 'b-');

    subplot(212);
    plot(obj.lag.time, obj.lag.L - obj.lag.L_tilde, 'k-');

    % Save
    data = obj.toStruct();
    save('syncData.mat', 'data');
```