%% extract behavior data
% put the new data into the NewData folder
% then run this script to copy the data into the Data folder
% and then run GoNoGoAna
clear,clc
addpath(genpath('\\science\Li\Hanfei\GoNoGo\WorkC'))
%%
cd('\\science\Li\Hanfei\GoNoGo\OriginalData\20170322')
tem = subdir('*_Session*.mat');
DestiFolder = '\\science\Li\Hanfei\GoNoGo\GoNoGoPlot';

if numel(tem)>0
    for k=1:numel(tem)
        copyfile(tem(k).name,DestiFolder);
    end
else
    error('No data found. Please add data into NewData folder!');
end

cd(DestiFolder)