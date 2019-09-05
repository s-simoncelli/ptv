function this = computeRectificationError(this)
%COMPUTERECTIFICATIONERROR Computes the epipolar error by checking how well the
% points in the left image lie on the epipolar lines of the right image and
% viceversa. The meanEpipolarError provides a proxy about the goodness of
% the rectification process. The lower, the more accurate the rectification
% and the disparity map are.
%  OUTPUT:
%    error.mean       -  Mean epipolar error                   [double]
%    error.meanLeft   -  Mean epipolar errors in left frames   [matrix]
%    error.meanLeft   -  Mean epipolar errors in right frames  [matrix]
%    epilines.left    -  Epipolar lines coefficients           [matrix]
%    epilines.right   -  Epipolar lines coefficients           [matrix]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    this.epilines.left = [];
    this.epilines.right = [];
    
    points.left = [];
    points.right = [];

    for frame=1:this.totalFrames
        F = this.stereoParams.FundamentalMatrix;

        corners.left = this.imagePoints(:, :, frame, 1);
        corners.right = this.imagePoints(:, :, frame, 2);


        % From the fundamental matrix definition line epilines2 in the second
        % image for the point P1 in the first image is computed as:
        %     epilines2 = F * P1
        %
        % Whereas epilines1 is computed from P2 as:
        %     epilines1 = F^T * P2

        % Compute the epipolar lines in the left image using the points in the
        % right image as reference. If F is the fundamental matrix of the pair 
        % of cameras 1->2 then F' is the fundamental matrix of the pair in 
        % the opposite order 2->1
        tmp = epipolarLine(F', corners.right);
        this.epilines.left = [this.epilines.left; tmp];

        % Compute the epipolar lines in the right image using the points in the
        % left image as reference.
        tmp = epipolarLine(F, corners.left);
        this.epilines.right = [this.epilines.right; tmp];

        % Compute undistorted points in left
        tmp = undistortPoints(corners.left, this.stereoParams.CameraParameters1);
        tmp = [tmp ones(size(tmp, 1), 1)];
        points.left = [points.left; tmp];

        % Compute undistorted points in right
        tmp = undistortPoints(corners.right, this.stereoParams.CameraParameters2);
        tmp = [tmp ones(size(tmp, 1), 1)];
        points.right = [points.right; tmp];
    end

    % epipolar geometry constraint P2' * F * P1 = 0
    % Being epilines2 = F * P1 it follows P2 * epilines2 = 0
    this.rectificationError.left = abs(sum(points.left .* this.epilines.left, 2));
    this.rectificationError.right = abs(sum(points.right .* this.epilines.right, 2));
    this.rectificationError.meanLeft = mean(this.rectificationError.left);
    this.rectificationError.meanRight = mean(this.rectificationError.right);
    this.rectificationError.mean = (this.rectificationError.meanLeft  + this.rectificationError.meanRight)/2;
end