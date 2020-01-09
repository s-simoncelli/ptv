function this = match(this)
%MATCH Find the correct match of a particle in the left frame.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    for row=1:this.totalLeftParticles
        % Particle data
        cL = this.leftParticles.centroid(row, :);
        cR = this.rightParticles.centroid;

        % in the image X and Y are flipped
        % box(1) = X (column id)
        % box(2) = Y (row id)
        box = this.leftParticles.bbox(row, :);

        % Get sub frame of left particle and add padding around the
        % particle. This is needed to get the correlation
        s = this.subFramePadding;

        min_x = max([1 box(1)-s]);
        max_x = min([box(1)+box(3)+s this.imageSize(1)]);

        min_y = max([1 box(2)-s]);
        max_y = min([box(2)+box(4)+s this.imageSize(2)]);

        leftParticlesFrame = this.leftFrame(min_y:max_y, min_x:max_x);

        % Get particles within the searching area
        searchingArea = [];
%         searchingArea(:, 1) = [cL(1) 0 0 cL(1)];
        
        % minX is the rectangle left edge
        if(~isnan(this.maxDisparity))
            minX = max([0 cL(1)-this.maxDisparity]);
        else
            minX = 0;
        end
        
        % maxX is the rectangle right edge
        if(~isnan(this.minDisparity))
            maxX = min([cL(1) cL(1)-this.minDisparity]);
        else
            maxX = cL(1);
        end

        searchingArea(:, 1) = [maxX minX minX maxX];
        l = this.searchingAreaPadding/2;
        searchingArea(:, 2) = cL(2) + [-l -l +l +l];

        in = inpolygon(cR(:, 1), cR(:, 2), searchingArea(:, 1), searchingArea(:, 2));

        % Define candidate for matching
        candidates = this.rightParticles(in, :);
        additionalData = table('Size', [height(candidates), 2], 'VariableTypes', ...
            {'single', 'single'}, 'VariableNames', {'score', 'areaRatio'});
        candidates = [candidates, additionalData];

        % get correlation by comparing left and right sub-frames
        totalCanidates = size(candidates.bbox, 1);
        scoreTable = table;
        for l=1:totalCanidates
            box = candidates.bbox(l, :);
            x = box(2):box(2)+box(4)-1;
            y = box(1):box(1)+box(3)-1;

            candidateFrame = this.rightFrame(x, y);

            % if the right-frame particle has a bigger area, normxcorr2 cannot
            % be used. It also means that (1) the particle to verify is larger
            % and is not a match or (2) the particle is the one to match but it
            % appears larger in the right frame with rispect ot the left one.
            % In either cases, neglect it.
            % A must be > template
            A = leftParticlesFrame;
            template = double(candidateFrame); % convert to double for std

            if(size(A, 1) < size(template, 1) || size(A, 2) < size(template, 2))
                candidates.score(l) = NaN;
                continue;
            end

            % if the templayte values are all the same, comparison is
            % meaningless
            if(isempty(template) || std(template(:)) == 0)
                candidates.score(l) = NaN;
                continue;
            end

            % cross-correlation
            Icorr = normxcorr2(template, A);
            maxCorr = round(max(abs(Icorr(:))), 5); % score
            candidates.score(l) = maxCorr;
        end
        
        % count particle with template area > A for all candidates
        this.count.noScore = this.count.noScore + (isempty(candidates.score) && totalCanidates > 0);
        
        % convert area to single from intX
        candidates.areaRatio = single(table2array(candidates(:, 'area'))) ./ ...
            single(table2array(this.leftParticles(row, 'area')));
        
        if(this.debug)
            scoreTable = table(candidates.id, candidates.area, candidates.score, ...
                candidates.areaRatio, false(height(candidates), 1), ...
                    false(height(candidates), 1), 'VariableNames', {'rightParticleId', 'area', ...
                    'score', 'areaRatio', 'possibleMatch', 'selected'});
            
            this.scoreData.leftToRight(row).leftParticleId = this.leftParticles.id(row);
            this.scoreData.leftToRight(row).data = scoreTable;            
        end
        
        % Match the particle
        I = find(candidates.score >= this.minScore  & ...
            (candidates.areaRatio >= this.minAreaRatio & candidates.areaRatio <= this.maxAreaRatio));

        this.matchData.leftParticleId(row) = this.leftParticles.id(row);
        this.matchData.rightParticleId(row) = NaN;
        this.matchData.areaRatio(row) = NaN;
        this.matchData.score(row) = NaN;
        this.matchData.disparity(row) = NaN;

        if(~isempty(I) && this.debug)
            this.scoreData.leftToRight(row).data.possibleMatch(I) = true;
        end
        
        if(length(I) > 1)
            subset = candidates(I, :);
            matchedWidth = NaN;
            
            % get particles with highest score, but only if there's one and
            % the score is high enough to consider it a safe match    
            % get particles with highest score, but only if there's only one 
            % and its score is high enough to consider it as a safe match    
            D = find(subset.score >= this.minScoreForMultipleMatches);
            if(~isempty(D) && length(D) == 1)
                [~, D] = max(subset.score);
                this.matchData.rightParticleId(row) = subset.id(D);
                this.matchData.score(row) = subset.score(D);
                this.matchData.areaRatio(row) = subset.areaRatio(D);
                this.matchData.disparity(row) = round(...
                    (this.leftParticles.centroid(row, 1) - subset.centroid(D, 1)), 4);
                matchedWidth = subset.id(D);
            end

            if(this.debug)
                data = table(candidates.id(I), candidates.score(I), ...
                    candidates.areaRatio(I), ...
                    'VariableNames', {'rightParticleId', 'score', 'areaRatio'});
                newRow = table(this.leftParticles.id(row), {data}, matchedWidth, ...
                    'VariableNames', {'leftParticleId', 'data', 'matchedWidth'});
                this.multipleMatches = [this.multipleMatches; newRow];
            end
        elseif(length(I) == 1)
            this.matchData.rightParticleId(row) = candidates.id(I);
            this.matchData.score(row) = candidates.score(I);
            this.matchData.areaRatio(row) = candidates.areaRatio(I);
            this.matchData.disparity(row) = round(...
                (this.leftParticles.centroid(row, 1) - candidates.centroid(I, 1)), 4);
        end

        % Update scoreData with the correct match
        rightId = this.matchData.rightParticleId(row);
        if(this.debug && ~isnan(rightId))
            I = find(scoreTable.rightParticleId == rightId);
            if(~isempty(I))
                this.scoreData.leftToRight(row).data.selected(I) = true;
            end

        end
    end
    
    if(this.debug)
        this.scoreData.leftToRight = struct2table(this.scoreData.leftToRight);
    end
end
