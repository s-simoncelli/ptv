function this = saveData(this)
%SAVEDATA Exports non-saved data to file

    notSaved = this.system.saved == 0;
    data = this.system(notSaved, :);
    data = removevars(data, 'saved'); % column not needed
    data = table2array(data);
    
    % check if the file is too big (> 300 MB), if so split the data in a new file
    fileStats = dir(this.trackFile);
    if(fileStats.bytes*10^-6 > this.maxTrackFileSize) 
        this.trackFileCounter = this.trackFileCounter + 1;
        [~, fileName] =  fileparts(this.trackFile);
    
        if(this.trackFileCounter == 1)
            fileName = sprintf('%s_%d.txt', fileName, this.trackFileCounter);
        else
            findStr = sprintf('_%d.txt', this.trackFileCounter-1);
            findRep = sprintf('_%d.txt', this.trackFileCounter);
            f = sprintf('%s.txt', fileName);
            fileName = strrep(f, findStr, findRep);
        end
  
        this.trackFile = fullfile(this.logFolder, fileName);
        this.createTrackFile(this.trackFile);
    end
    
    dlmwrite(this.trackFile, data,  'delimiter', '\t', 'precision', 7, '-append');

    this.system.saved(notSaved) = 1;
    this.lastSaved = this.step.counter;
end

