function this = exportScoreRightToLeft(this)
%EXPORTSCORERIGHTTOLEFT ExportS score data of particles from right to left.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    for l=1:height(this.scoreData.leftToRight)
       leftId = this.scoreData.leftToRight.leftParticleId(l);
       leftParticleData = this.scoreData.leftToRight.data{l};
       if(isempty(leftParticleData))
           continue;
       end

       rightIds = leftParticleData.rightParticleId;
       scores = leftParticleData.score;
       rows = ismember(this.rightParticles.id, rightIds);
       areas = this.rightParticles.area(rows);

       % data in this.scoreData are assigned by ID so that each row number
       % matched the ID
       for j=1:length(rightIds)
           id = rightIds(j);
           % find row if already exists (id -> I)
           I = find([this.scoreData.rightToLeft.rightParticleId] == id);
           
           if(isempty(I))
               this.scoreData.rightToLeft(id).rightParticleId = id;
               this.scoreData.rightToLeft(id).data = table( ...
                   leftId, scores(j), areas(j), ...
                   'VariableNames', {'leftId', 'score', 'area'});
           else
               newRow = table( ...
                   leftId, scores(j), areas(j), ...
                   'VariableNames', {'leftId', 'score', 'area'});
               this.scoreData.rightToLeft(id).data = [...
                   this.scoreData.rightToLeft(id).data; newRow];
           end
       end

    end
    % remove empty rows
    t = this.scoreData.rightToLeft;
    this.scoreData.rightToLeft = t(~cellfun(@isempty,{t.rightParticleId}));
end