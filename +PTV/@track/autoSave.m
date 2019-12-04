function [this] = autoSave(this)
%AUTOSAVE saves tracks in a text file every 'autoSaveEvery' frames.
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    tic;
    
    if(this.step.counter - this.lastSaved > this.autoSaveEvery)
        this = this.saveData();
        this.logStatus('Autosaved data', false);
    end
    
    if(this.showVideoPlayers)
        % Purge lost track only. Data of saved track are still needed for plotting
        tracksToPurge = this.system.saved == 1 & this.system.lost == 1;
        this.system(tracksToPurge, :) = [];
    else
        % Clean up all saved data
        tracksToPurge = this.system.saved == 1;
        this.system(tracksToPurge, :) = [];
    end
    
    this.logStatus(sprintf('Step #%d - Auto-saving took %.3f seconds', ...
        this.step.counter, toc), false);
end

