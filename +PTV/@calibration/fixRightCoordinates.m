function this = fixRightCoordinates(this)
%FIXRIGHTCOORDINATES Fix coordinates from chequerboards detected from the
%right camera to ensure video synchronisation.
    
    fprintf('>> Fix coordinates from chequerboards detected from the right camera to ensure video synchronisation.\n');

    for fr=1:this.totalFrames
        % get frame number from image
        [~, fName] = fileparts(this.imagesLeftAll{fr});
        tmp = strsplit(fName, '_');
        F1 = str2double(tmp{end});

        I = find(this.lagData.lag.F1 == F1);
        if(isempty(I))
            error('Cannot find delay data for frame #%d', F1);
        end
        L = this.lagData.lag.L(I);
        tau = this.lagData.lag.tau(I);

%     figure; hold on;
%     plot(squeeze(this.imagePointsRight(:, 1, fr)), squeeze(this.imagePointsRight(:, 2, fr)), 'k.')


        %% % j=1 is delayed (L > 0)
        if(L > 0)
            for c=1:2 % x and y
                % slope
                mik_x = this.imagePointsRightPlus(:, c, fr) - this.imagePointsRight(:, c, fr);
                this.imagePointsRight(:, c, fr) = this.imagePointsRight(:, c, fr) + mik_x*tau;
            end

        %% % j=2 is advanced (L < 0)
        else
            if(tau > 0)
                for c=1:2 % x and y
                    % slope
                    mik_x = this.imagePointsRightPlus(:, c, fr) - this.imagePointsRight(:, c, fr);
                    this.imagePointsRight(:, c, fr) = this.imagePointsRight(:, c, fr) + mik_x*tau;
                end
            else
                for c=1:2 % x and y
                    % slope
                    mik_x = this.imageRightPoints(:, c, fr) - this.imagePointsRightMinus(:, c, fr);
                    this.imagePointsRight(:, c, fr) = this.imagePointsRight(:, c, fr) + mik_x*tau;
                end                
            end
        end
% plot(squeeze(this.imagePointsRight(:, 1, fr)), squeeze(this.imagePointsRight(:, 2, fr)), 'ro')

    end
end

