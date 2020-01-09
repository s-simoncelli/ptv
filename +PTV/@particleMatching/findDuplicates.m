function this = findDuplicates(this)
%FINDDUPLICATES Find particles in right frame that have multiple matches with a 
% particle in the left frame. This may happen when:
%  A) 2 or more particles in the left frame are very close and 
%     both are included in the padded sub-frame. 
%  B) particles in the left are afar and matches one particle i
%    the right frame,. For each L particle there is one match in the
%    right frame with high score (> this.minScore). L and R particles are 
%    similar, where usually the R particle is smaller and fits within the L
%    particle. In this case correlation is similar and high as well as
%    the L and R particles area, so that it is not safe to match them.
%
% In such cases the matches are ignored.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

   
    A = this.matchData.rightParticleId;
    A = A(~isnan(A));
    [~, I] = unique(A);
    repeatedIdx = setdiff(1:length(A), I);
    % this contains all repeated duplicates
    duplicateRightIds = sort(A(repeatedIdx));
    duplicateRightIds = unique(duplicateRightIds);
    this.count.rightDuplicates = length(duplicateRightIds);

    for row=1:length(duplicateRightIds)
        rId = duplicateRightIds(row);
        % rows of duplicated left particles
        rowsToUpdate = this.matchData.rightParticleId == rId;
        % IDs of duplicated left particles
        lIds = this.matchData.leftParticleId(rowsToUpdate);
        
        if(this.debug)
            this.duplicatedMatches(row).rightParticleId = rId;
            this.duplicatedMatches(row).leftParticleDuplicatedIds = lIds;
        end
        
        % remove all matches
        this.matchData.rightParticleId(rowsToUpdate) = NaN;
        this.matchData.disparity(rowsToUpdate) = NaN;
        this.matchData.score(rowsToUpdate) = NaN;
        this.matchData.areaRatio(rowsToUpdate) = NaN;
        
        if(this.debug)
            for j=1:length(lIds)
                lId = lIds(j);
                I = find(this.scoreData.leftToRight.leftParticleId == lId);
                this.scoreData.leftToRight.data{I}.selected(:) = false;            
            end
        end
    end
end

