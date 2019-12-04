function [str] = formatDuration(durationInSecs)
%FORMATDURATION Format a duration in seconds as  hh:mm:ss
%
%  INPUT:
%    durationInSecs  -  Duration in seconds. It can be a double or
%                       a duration class                      [double/duration]
%
%  OUTPUT:
%    str             -  Formatted duration                    [string]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    if(isa(durationInSecs, 'double'))
        durationInSecs = seconds(durationInSecs);
    end
        
    str = duration(durationInSecs, 'Format', 'hh:mm:ss');
end

