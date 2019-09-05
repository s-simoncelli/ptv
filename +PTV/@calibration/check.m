function this = check(this, frameLeft, frameRight)
%Verify that the calibration is able to provide a proper
%disparity map and reconstruct the 3D scene.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    
    % convert to uint8 to improve the speed of disparity
    image.leftFrame = uint8(frameLeft);
    image.rightFrame = uint8(frameRight);
    image.merged = cat(2, image.leftFrame, image.rightFrame);
    image.merged = insertObjectAnnotation(image.merged, 'rectangle', [0 0 20 20], ...
        'Original frames', 'FontSize', 50);
    
    %% Undistorted images - to check distortion coefficients
    image.leftUndistorted = undistortImage(image.leftFrame, ...
        this.stereoParams.CameraParameters1, 'OutputView', 'same');
    image.rightUndistorted = undistortImage(image.rightFrame, ...
        this.stereoParams.CameraParameters2, 'OutputView', 'same');

    image.UndistortedMerged = cat(2, image.leftUndistorted, image.rightUndistorted);
    image.UndistortedMerged = insertObjectAnnotation(image.UndistortedMerged, 'rectangle', [0 0 20 20], ...
        'Undistorted frames', 'FontSize', 50);

    figure;
    imshow(cat(1, image.merged, image.UndistortedMerged), 'InitialMagnification', 50);
    
    %% Rectification
    fprintf('>> Rectification\n');
    [image.leftFrameRect, image.rightFrameRect] = ...
        rectifyStereoImages(image.leftFrame, image.rightFrame, this.stereoParams, 'OutputView', 'valid');
    this.imageSizeRect = size(image.leftFrameRect);

    % Plot
    figure;
    Y = 1:30:this.imageSizeRect(1);
    Y = Y'.*ones(length(Y), 2);
    X = [0 this.imageSizeRect(2)].*ones(length(Y), 1);
    C = PTV.distinguishable_colors(size(X, 1))*255;
    image.rectLeft = insertShape(image.leftFrameRect, 'Line', ...
        [X(:, 1) Y(:, 1) X(:, 2) Y(:, 2)], 'LineWidth', 2, 'Color', C);
    image.rectRight = insertShape(image.rightFrameRect, 'Line', ...
        [X(:, 1) Y(:, 1) X(:, 2) Y(:, 2)], 'LineWidth', 2, 'Color', C);

    image.rectMerged = cat(2, image.rectLeft, image.rectRight);
    image.rectMerged = insertObjectAnnotation(image.rectMerged, 'rectangle', [0 0 20 20], ...
        'Rectified+epilines', 'FontSize', 50);
    imshow(image.rectMerged, 'InitialMagnification', 50);
    
    imageSizeDepth = size(image.leftFrameRect, 3);
    isRGB = (imageSizeDepth == 3);

    if(isRGB) % RGB image
        image.leftFrameGrey  = rgb2gray(image.leftFrameRect);
        image.rightFrameGrey = rgb2gray(image.rightFrameRect);
    else % image is already gray-scaled
        image.leftFrameGrey  = image.leftFrameRect;
        image.rightFrameGrey = image.rightFrameRect;
    end
   
    warning('visionToolboxCalibration:imtool', ...
        'Make sure to set the correct value for config.maxDisparity using the imtool. This must be a mutiple of 16');
    
    imtool(stereoAnaglyph(image.leftFrameRect, image.rightFrameRect));

    %% Disparity function uses -realmax('single') to mark pixels for which
    % disparity estimate is unreliable
    fprintf('>> Calculating disparity map\n');
    this.disparityMap = disparity(image.leftFrameGrey, image.rightFrameGrey, ...
        'method', 'SemiGlobal', ...
        'BlockSize', this.disparityBlockSize, ...
        'ContrastThreshold', this.disparityContrastThreshold, ...
        'UniquenessThreshold', this.disparityUniquenessThreshold, ...
        'DisparityRange', [0 this.disparityMax]);
    
    % count pixels marked as invalid (see notes in reconstructScene)
    this.invalidDisparityCount = length(find(this.disparityMap == -realmax('single')));
    totalCount = numel(this.disparityMap);
    fprintf('>> %d/%d (%.2f%%) pixels have been marked as invalid\n', this.invalidDisparityCount, ...
        totalCount, this.invalidDisparityCount/totalCount*100);

    % count pixels whose disparity is zero. The world coordinates will be 
    % set to Inf by reconstructScene (see notes in reconstructScene)
    invalidCount = length(find(this.disparityMap == 0));
    fprintf('>> %d/%d (%.2f%%) pixels have 0 disparity, hence invalid (infinite) Z\n', invalidCount, ...
        totalCount, invalidCount/totalCount*100);
    
    this.invalidXYZCount = this.invalidDisparityCount + invalidCount;
    
    if(this.invalidXYZCount/totalCount > 0.5)
        warning('visionToolboxCalibration:invalidXYZ', ...
        'The calculated disparity map generates more than 50%% of invalid XYZ coordinates');
    end
    
    % remove high values (invalid disparities). Apparently MATLAB does not
    % limit values to DisparityRange
    this.validDisparityMap = this.disparityMap;
    this.validDisparityMap(this.validDisparityMap <= 0 | this.validDisparityMap > this.disparityMax) = NaN;
    fprintf('>> Max disparity: %.2fpx. Min disparity: %.2fpx\n',  ...
        max(this.validDisparityMap(:)), min(this.validDisparityMap(:)));

    warning('off', 'images:initSize:adjustingMag');
    figure;
%     imshow(disparityMap, [0 this.DisparityConfig.maxDisparity]);
    imagesc(this.validDisparityMap);
    b = colorbar;
    ylabel(b, 'Disparity');
    cMap = colormap('gray');
    cMap = [0 1 0; cMap]; % associate colour to NaNs
    colormap(cMap);
    
    title('Disparity Map');
    
    %% Reconstruct the 3-D Scene
    fprintf('>> Reconstructing the 3D scene\n');
    % Disparity function uses -realmax('single') to mark pixels for which
    % disparity estimate is unreliable. For such pixels reconstructScene
    % sets the world coordinates to NaN. For pixels with zero disparity,
    % the world coordinates are set to Inf.
    % The 3-D world coordinates are relative to the optical center of camera 1
    % of the stereo system represented by this.stereoParams.
    this.points3D = reconstructScene(this.disparityMap, this.stereoParams);
    this.points3D = this.points3D ./ 1000; % convert to metres

    if(~isRGB) % gray-scaled image
        C = image.leftFrameRect(:, :, [1 1 1]); % grayscale in RGB format
    else
        C = image.leftFrameRect;
    end
    this.ptCloud = pointCloud(this.points3D, 'Color', C);

    plot3DScene(this);
end

