function [this] = exportSettings(this)
%EXPORTSETTINGS exports tracking settings.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    vars = {'stereoCalibrationFile', 'trackFile', 'logFile', 'leftCameraPath', ...
        'rightCameraPath', 'videoLagFile', 'leftVideos', 'rightVideos', 'mexopencvPath', ...
        'numberOfFrames', 'totFramesInPreviousVideos', 'showVideoPlayers', ...
        'rotateLeftFrame', 'rotateRightFrame', 'enableLogging', ...
        'startingTime', 'startingVideo', 'numberOfTrainingFrames', 'autoSaveEvery', ...
        'maxTracks', 'frameRate', 'unit', 'blobDetectionSettings', ...
        'trackDetectionSettings', 'kalmanSettings', 'matchParticlesSettings', ...
        'baseLine', 'focalLength', 'principalPoint', 'stereoParams' ...
    };

    S = struct();
    for i=1:length(vars)
        var =  vars{i};
        if(strcmp(var, 'frameRate') || strcmp(var, 'leftVideos') || strcmp(var, 'rightVideos'))
            S.(var) = this.video.(var);
            continue;
        elseif(strcmp(var, 'stereoParams'))
            data = this.(var).toStruct;
            data.CameraParameters1 = rmfield(data.CameraParameters1, 'WorldPoints');
            data.CameraParameters1 = rmfield(data.CameraParameters1, 'TranslationVectors');
            data.CameraParameters1 = rmfield(data.CameraParameters1, 'RotationVectors');
            data.CameraParameters1 = rmfield(data.CameraParameters1, 'ReprojectionErrors');
            
            data.CameraParameters2 = rmfield(data.CameraParameters2, 'WorldPoints');
            data.CameraParameters2 = rmfield(data.CameraParameters2, 'TranslationVectors');
            data.CameraParameters2 = rmfield(data.CameraParameters2, 'RotationVectors');
            data.CameraParameters2 = rmfield(data.CameraParameters2, 'ReprojectionErrors');
            S.(var) = data;
            continue;
        end
        S.(var) = this.(var);
    end
    
    fileName = sprintf('settings_%s.yml', this.dateFmt);
    fileName = fullfile(this.logFolder, fileName);
    cv.FileStorage(fileName, S);
    this.logStatus(sprintf('Settings exported to %s', fileName), false);
end

