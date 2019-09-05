clc; clear; close all;

addpath('../..');

lagData = './lagData.mat';

obj = PTV.calibration(...
    '.', 21.7, lagData, 'Name', 'stereo_cal1', 'CheckFrameNumber', 8, ...
    'DisparityBlockSize', 5, 'DisparityContrastThreshold', 0.1, ...
    'DisparityUniquenessThreshold', 0, 'DisparityMax', 16*9);
