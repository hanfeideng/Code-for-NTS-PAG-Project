function [varargout]= ReadMouseOxFile(filename)
% This is used to read the Events information from MouseOx
% Author: Xiong Xiao; Data: 2019-11-06

% Input: the MouseOx File to analyze
% Output: the Event timestamp

switch nargin
    case 0
        filename='';
        if (isempty(filename))
            [fname, pathname] = uigetfile('*.txt', 'Select a MouseOx File to process: ');
            if isequal(fname,0)
                error 'No file was selected'
            end
            filename = fullfile(pathname, fname);
            cd(pathname);
        end
    case 1
        filename=filename;
end

% [pathstr,name,ext,versn]=fileparts(filename);
[pathstr,name,~]=fileparts(filename);
if ~isempty(pathstr)
    cd(pathstr);
end

fid=fopen(filename);
flag=1; A = [];
while ~feof(fid)
    lineinfo=fgetl(fid);
    temp_data=sscanf(lineinfo,'%[^\n]');
    
    temp_p=find(temp_data==',');
    
    
    A{flag,1} = temp_data(1:temp_p(1)-1);
    for k=2:length(temp_p)
        A{flag,k} = temp_data(temp_p(k-1)+1:temp_p(k)-1);        
    end
    A{flag,length(temp_p)+1} = temp_data(temp_p(end)+1:end);
    flag = flag+1;
    
end
fclose(fid);

if nargout==1 
  varargout{1} = A;
end
