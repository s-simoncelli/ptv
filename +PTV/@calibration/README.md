# Introduction

This MATLAB package estimates the calibration parameters of a 
stereo camera system that records asynchronised video streams. Type

    help PTV.calibration

or

    doc PTV.calibration

anytime in the MATLAB Command Window to recall the following documentation.

# Usage
 ```matlab
    path to frames extracted with PTV.extractCalibrationFrames
    pathToFrames = '/path/to/images';
    size of the chequerboard square
    squreSize = 30; mm

    obj = calibration(pathToFrames, squreSize);
    obj = calibration(..., 'Name', 'stereo_cal');
    obj = calibration(..., 'Exclude', [1 3 5]);
    obj = calibration(..., 'SaveSummary', false);
    obj = calibration(..., 'CheckFrameNumber', 14);
```

  `PTV.calibration()` requires the following parameters:
  1) Path of the frames extracted with PTV.extractCalibrationFrames.
  2) Size of the chequerboard squares in mm.

`obj = PTV.calibration(..., Name, Value)` specifies additional name-value pairs described below:

- **name** -  Name of the calibration. Default: `cal`
- **exclude** -   Frame IDs to exclude from the calibration set. For example to exclude images `f1` and `f4`, use [1 4]. This is useful to exclude frames with high reprojection errors. Default: []
- **saveSummary** -  Save plots with calibration results. Default: true
- **checkFrameNumber** -   Frame number to use to verify the calibration (i.e to compute the disparity and reconstruct the 3D scene). You can also verify the calibration using a frame pair not belonging to the calibration set by calling the `check` method. Default: first frame included in the calibration set. The set includes frames with detected chequerboard corners and includes frames that have not been exluded with the `Exclude` setting.
- **disparityBlockSize** -  Width of each square block whose pixels are used for comparison between the images.  Default: 15. Max: 255. Min: 5.
- **disparityMax** -  Maximum value of disparity. Run the calibration at least once to measure the maximum distance using the imtool from the stereo anaglyph. Default: 64. 
- **disparityContrastThreshold** - Acceptable range of contrast values. Increasing this parameter results in fewer pixels being marked as unreliable. Default: 0.5. Max: 1. Min: 0. 
- **disparityUniquenessThreshold** -  Minimum value of uniqueness. Increasing this parameter results in the function   marking more pixels unreliable. When the  uniqueness value for a pixel is low, the  disparity computed for it is less reliable. Default: 15.


`obj = PTV.calibration(...)` returns a *calibration* object containing the output of the lag estimation.

# calibration properties
## Frames data
- **imagesLeftAll**  - Path to files from left camera
- **imagesRightAll** - Path to files from right camera
- **fileNamesAll** - File names in the path
- **fileNames** - File names in the calibration set

## Corner-detection output
- **imagePointsLeft** - Detected points in frames from left cameras. See `detectchequerboardPoints`
- **imagePointsRight**  - Detected points in frames from right cameras. These points have been fixed to ensure frame synchronisation.
- **imagePoints** - Pattern points used in the calibration.
- **worldPoints** - Real world points of chequerboard. See `generatechequerboardPoints`
- **boardSize** - Number of rows and columns in chequerboard. See `detectchequerboardPoints`
- **imagesUsed** - Frames where the pattern was detected. See `detectchequerboardPoints`
- **imageSize**- Size of the frame in pixels
- **totalFrames** - Total number of valid and non-excluded frames used in the calibration set. 

## Calibration output
- **stereoParams** - Calibration parameters. See `stereoParameters`
- **pairsUsed** - Frames used in the calibration. See `estimateCameraParameters`
- **estimationErrors** - Calibration errors. See `estimateCameraParameters`
- **rectificationError** - Rectification errors in each frame.
- **epilines** - Epipolar lines for each frame. See `epipolarLine`

## Verification output
- **imageSizeRect** - Size of rectified frames in pixels.
- **disparityMap** - Disparity map for `CheckFrameNumber`
- **validDisparityMap** - Valid values of disparity map for `CheckFrameNumber`
- **invalidDisparityCount**  - Number of invalid pixels in the disparity map
- **points3D** - World coordinates (metres) of the points in the 3D scene
- **invalidXYZCount** - Number of invalid world points in the 3D scene
- **ptCloud** - points3D as pointCloud object. See `pointCloud`

`obj = PTV.calibration(...)` provides the following public methods:

- **plotErrors** - Plot reprojection and rectification histograms.
- **plotPatternLocations** - Plot 3D location of chequerboards.
- **plotCameraModel**      - Plot the camera models (accounting for radial and tangential distortions) and the relative position of the two cameras.
- **plotSummary**    - Run the 3 above methods together.
- **plot3DScene**    - Plot the 3D scene of `CheckFrameNumber` frame.
- **plotDiscardedFrames** - Plot frames where the chequerboard corners were not fully detected.
- **plotExcludedFrames**   - Check which frames were excluded with the `Exclude` option.
- **check**                - Check that the calibration works by correctly estimating the disparity map and reproducing the 3D scene for a provided frame pair.
- **compareRectifiedChequerboards** - Compare rectified frames containing the chequerboards used in the calibration. Chequer edges should be row-aligned  according to epipolar geometry.

 # Example
 ```matlab
    clc; clear; close all;

    addpath('/path/to/ptv/package');

    import PTV.*

    lagData = '/Volumes/stereo_cameras/calibrations/syncData.mat';

    obj = PTV.calibration(...
        '/Volumes/stereo_cameras/calibrations/cal_4/', ...
        21.7, lagData, 'Name', 'stereo_cal4',  'CheckFrameNumber', 8, ...
        'DisparityBlockSize', 5, 'DisparityContrastThreshold', 0.1, ...
        'DisparityUniquenessThreshold', 0, 'DisparityMax', 16*9);

```
