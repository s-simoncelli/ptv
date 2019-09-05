function player = plot3DScene(this)
%PLOT3DSCENE Plots the 3D point clouds from reconstructScene and pointCloud
%outputs.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    % Create a streaming point cloud viewer
    l = zeros(3, 2);
    for i=1:3
        a = this.points3D(:, :, i);
        l(i, 1) = nanmin(a(~isinf(a)));
        l(i, 2) = nanmax(a(~isinf(a)));
    end
    player = pcplayer(l(1, :), l(2, :), l(3, :), 'VerticalAxis', 'y', ...
        'VerticalAxisDir', 'down');
    show(player);
    view(player, this.ptCloud);
    cameratoolbar;
end

