function fileList = loadFiles(pathToScan, videoExt)
%LOADFILES Load the video files in the provided directory.
%
%  INPUT:
%    pathToScan  -  Path where video files are                    [string]
%    videoExt    -  Extension of the video files                  [string]
%
%  OUTPUT:
%
%    fileList    -  List of files                                 [struct]
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>
    
   list = dir(sprintf('%s/*.%s', pathToScan, videoExt));
   
   I = ismember({list.name}, {'.', '..'});
   list(I) = [];
   
   j = 1;
   fileList = [];
   for f=1:length(list)
      if(strcmp(list(f).name(1), '.'))
          continue;
      end
      fileList{j}.fullFile = fullfile(pathToScan, list(f).name);
      fileList{j}.fileName = list(f).name;
      j = j + 1;
   end
   
   if(isempty(fileList))
       error('Cannot find files in %s', pathToScan);
   end
end

