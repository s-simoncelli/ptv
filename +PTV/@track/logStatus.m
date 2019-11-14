function logStatus(this, message, print)
%LOG Logs the status messages of the system, such as number of particles
%found at each step.
%
%  INPUT:
%    trackIdx    -  The message to  log                              [string]
%    print       -  Wether to print the message in the command windo [bool]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
    if(nargin == 2)
        print = true;
    end

    if(this.enableLogging)
        fid = fopen(this.logFile, 'a+');

        t = datestr(now, 'mmm dd HH:MM:SS');
        content = sprintf('[%s]  %s', t, message);
        fprintf(fid, '%s\n', content);
        fclose(fid);
    end
    
    if(print)
        fprintf('>> %s\n', message);
    end
end

