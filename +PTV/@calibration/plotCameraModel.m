function h = plotCameraModel(this)
%PLOTCAMERAMODEL Plots the camera models (accounting for radial and
%tangential distortions) and the relative position of the two cameras in
%terms of translation and rotation.
%
%REFERENCE: https://docs.opencv.org/3.2.0/d9/d0c/group__calib3d.html#details
%AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    h = figure;
    for d=[1 2]
        camera = sprintf('CameraParameters%d', d);
        cal = this.stereoParams.(camera);

        %% A=[fx 0 cx; 0 fy cy; 0 0 1] is the camera matrix or the matrix of
        % intrinsic parameters, where cx and cy represents the?principal point
        % (centres of coordinates on the projection screen) and fx and fy the 
        % focal lengths.
        A = [cal.FocalLength(1) 0 cal.PrincipalPoint(1); ...
            0 cal.FocalLength(2) cal.PrincipalPoint(2); ...
            0 0 1
        ];

        %% distortion coefficients matrix
        % D=[k1 k2 p1 p2 k3 k4 k5 k6 s1 s2 s3 s4 taux tauy] where k is the
        % coefficient for radial distortion, p for tangential distortion and 
        % s the thin prism distortion coefficients (not estimated by MATLAB).
        % The coefficients k3 to k6 come from the rational model not used in
        % MATLAB or by default by openCV (set them to 0). tau is the
        % coefficient for the tilted sensor model (not used in MATLAB).
        D = [cal.RadialDistortion(1:2) cal.TangentialDistortion ...
            cal.RadialDistortion(3)  0 0 0 0 0 0 0 0 0];
  
        nstep = 15;
        imageSize = cal.ImageSize(2:-1:1);
        [u, v] = meshgrid(linspace(0, imageSize(1)-1, nstep), ...
            linspace(0, imageSize(2)-1, nstep));
        xyz = A \ [u(:) v(:) ones(numel(u), 1)].';
        xp = xyz(1, :) ./ xyz(3, :);
        yp = xyz(2, :) ./ xyz(3, :);
        r2 = xp.^2 + yp.^2;
        r4 = r2.^2;
        r6 = r2.^3;
        coef = (1 + D(1)*r2 + D(2)*r4 + D(5)*r6) ./ (1 + D(6)*r2 + D(7)*r4 + D(8)*r6);
        xpp = xp.*coef + 2*D(3)*(xp.*yp) + D(4)*(r2 + 2*xp.^2) + D(9)*r2 + D(10)*r4;
        ypp = yp.*coef + D(3)*(r2 + 2*yp.^2) + 2*D(4)*(xp.*yp) + D(11)*r2 + D(12)*r4;
        u2 = A(1,1)*xpp + A(1,3);
        v2 = A(2,2)*ypp + A(2,3);
        du = u2(:) - u(:);
        dv = v2(:) - v(:);
        dr = reshape(hypot(du,dv), size(u));

        subplot(2, 2, d);
        quiver(u(:)+1, v(:)+1, du, dv)
        hold on
        plot(imageSize(1)/2, imageSize(2)/2, 'x', A(1,3), A(2,3), 'o')
        [C, hC] = contour(u(1,:)+1, v(:,1)+1, dr, 'k');
        clabel(C, hC)
        axis ij equal tight
        title(sprintf('Camera %d', d));
    end
    
    %% Plot translation and angles
    T = this.stereoParams.TranslationOfCamera2;
    [roll, pitch, yaw] = PTV.rotationMatToDeg(this.stereoParams.RotationOfCamera2);

    subplot(223); hold on;
    for t=1:3
        plot(t, T(t), '.', 'MarkerSize', 20);
    end
    title('Translation cam2 (mm)');
    set(gca, 'XTick', 1:3);
    legend('X', 'Y', 'Z');
    box on;

    subplot(224); hold on;
    plot(1, roll, '.', 'MarkerSize', 20);
    plot(2, yaw, '.', 'MarkerSize', 20);
    plot(3, pitch, '.', 'MarkerSize', 20);
    title('Rotation cam2 (deg)');
    set(gca, 'XTick', 1:3);
    legend('X', 'Y', 'Z');
    box on;
    
end

