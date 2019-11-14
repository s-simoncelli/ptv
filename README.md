# ptv

This repository contains the MATLAB package for the underwater particle tracking velocimetry (PTV) software used in:

> Simoncelli et al. 2019. A low-cost underwater particle tracking velocimetry system for measuring in-situ particle flux and sedimentation rate in low-turbulence environments. Limnology and Oceanography: Methods DOI:10.1002/lom3.10341

The following classes are vailable:
- **synvVideos**: it determines the video delay between two sets of video files based on the analysis of the audio signals.

- **parSynvVideos**: same as for synvVideos, but it uses MATLAB Parallel Computing toolbox for a faster delay estimation.

- **extractCalibrationFrames**: extracts synchronised video frames to be used in `PTV.calibration`

- **calibration**: estimates the calibration parameters of a stereo camera system that records asynchronised video streams.

- **track**: tracks particles from a stereo rig.

For a complete description of each algorithm, read the `README.md` file in each respective folders in `+PTV`
or type `help` or `doc` in the MATLAB Command Window followed by `PTV.*`, where * is the name of
the method you want to get help about.

# General usage instructions

## Camera calibration
Camera calibration must be performed with the cameras submerged (i.e. in a tank) by recording videos of the  calibration chequerboard in different configurations. 

When calibrating the camera make sure:

- The cameras must use the same configuration (in terms of resolution and FOV) as used for particle tracking in the field.
- For a proper estimation of the distortion coefficients, the checkerboard should be printed to fit an A4 sheet so that it coveres the majority of the FOV
- The pattern must be waterproofed via lamination with a non-glossy finish to avoid flickering. It should be glued to a rigid board to avoid any warping of the surface while holding it. Any bending of the pattern would affect the calibration reliability.

When the camera are submerged, ready to shoot and the calibration pattern is ready:

1. Start the cameras and video recording
1. Place the pattern in as many configuration as possible, by tiltied it no more than 45 degrees relative to the camera plane. Rotate it if possible too. Make sure to place the pattern always within the FOV and in particular near the edges and corners of the FOV where distortions are expected to be larger. Keep the pattern always in focus.
1. When placing the pattern in one location and oriention in the FOV, hold it still for a few seconds. After that move it to a new configuration. Holding the pattern still in the videos ensures a correct extrapolation of the frame for calibration without any blurring of the chequerboard.
1. Once you have recorded the pattern in as many configuration as possible (at least 15/20 times), turn off the cameras.
1. Copy the videos from the SD card onto a PC.

### Frame extractions
In order to extract the video frames when you held the pattern still, you can use the `PTV.extractCalibrationFrames` utility. To run it, you need to specify the timestamps in seconds of the frames you want to extract. To do this

1. Install VLC (https://www.videolan.org) along with the Time addon (https://addons.videolan.org/p/1154032/). The time addon let you get the precise timestamp in seconds of the frame when you stop the video.
1. Play the video with VLC from the **left camera**
1. When the pattern in the video is still, stop the video and write down the on-screen timestamp provided by the Time addon.
1. Play again the video and repeat point 3 until you reach the end of the video.
1. Open `+PTV/@extractCalibrationFrames/README.md` for an example how to execute the method.
1. The `PTV.extractCalibrationFrames` utility saves the syned frames from the left and right cameras in the `frames_left_camera` and `frames_right_camera` folders.

For additional guidance, read the README file in the type `extractCalibrationFrames` folder or type `doc PTV.extractCalibrationFrames` in the MATLAB Command Window.

### Estimating calibration parameters
1. To estimste the calibration coefficients, see the example provided in `+PTV/@calibration/README.md`. 
1. Change the parameters, such as the size of the chequerboard squares or the number of rows and columns in chequerboard. Refer to `+PTV/@calibration/README.md` for guidance.
1. The method saves a MATLAB workspace containing the `stereoParameters` object needed by `PTV.track`
1. Check that the reprojection and rectification errors are low; if not try removing frames with high errors using the `Exclude` option.

## Particle tracking
1. For particle tracking, see the example provided in `+PTV/@track/README.md`. 
1. Change the detection and tracking parameters, depending on your configuration.
1. Run the package. Read `+PTV/@track/README.md` for the tracking output data.