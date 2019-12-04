function [this] = estimateParticleLengths(this)
%ESTIMATEPARTICLELENGTH Estimates the particle lengths accounting for
%particle size and orientation. The particle is modelled as an ellipses by
%the vision.blobAnalysis algorithm.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    %% Pixel coordinates
    % centroid
    C(:, 1) = this.step.tracks.centroid(:, 1);
    C(:, 2) = this.step.tracks.centroid(:, 2);
    
    % NOTE:  in MATLAB the orientation is between -90 and 90 degs so that when 
    % we apply cos or sin function to the Y coordinate, it accounts that the
    % Y axis increases downards in the image.
    alpha = this.step.tracks.or;
    
    % NOTE: the axis, as it is called in MATLAB, is not an axis as per
    % definition of axis in ellipses, but it it twice its size.
    ax_mj = this.step.tracks.ax_mj/2;
    ax_mn = this.step.tracks.ax_mn/2;
    
    E(:, 1) = C(:, 1) + ax_mj.*cos(alpha);
    E(:, 2) = C(:, 2) - ax_mj.*sin(alpha); 

    F(:, 1) = C(:, 1) + sign(alpha).*ax_mn.*cos(pi/2-abs(alpha));
    F(:, 2) = C(:, 2) + ax_mn.*sin(pi/2-abs(alpha));

    d = this.step.tracks.disparity;
    
    %% Real-world coordinates (triangulation)
    C(:, 1) = this.baseLine./d.*(C(:, 1) - this.principalPoint(1));
    C(:, 2) = this.baseLine./d.*(C(:, 2) - this.principalPoint(2));
    
    E(:, 1) = this.baseLine./d.*(E(:, 1) - this.principalPoint(1));
    E(:, 2) = this.baseLine./d.*(E(:, 2) - this.principalPoint(2));
    
    F(:, 1) = this.baseLine./d.*(F(:, 1) - this.principalPoint(1));
    F(:, 2) = this.baseLine./d.*(F(:, 2) - this.principalPoint(2));
    
    this.step.tracks.length(:, 1) = 2 * sqrt( (C(:, 1) - E(:, 1)).^2 + ...
        (C(:, 2) - E(:, 2)).^2 );
    this.step.tracks.length(:, 2) = 2 * sqrt( (C(:, 1) - F(:, 1)).^2 + ...
        (C(:, 2) - F(:, 2)).^2 );
end

