function h=AreaPlot(t,y,SEM,LineColor,Transparency,LWide)
% This is used for ploting the transparency figures.
% Input: t: values for x-axis
%        y: values for y-axis (mean value)
%        SEM: standord error/sqrt(n)
%        LineColor:e.g. 'g','b','r',...
%        Transparency: default value: 0.4
%        LWide: the line width of plot
% Author: Xiong Xiao; Date: 2013-07-12

%% Set the default parameters
if nargin<4
    LineColor='k';
end
if nargin<5
    Transparency=0.4;
end
if nargin<6
    LWide=2;
end

%%
h=plot(t,y,'Color',LineColor,'LineWidth',LWide);
hold on
upper=y+SEM;
lower=y-SEM;
yaxis=[upper,fliplr(lower)];
xaxis=[t,fliplr(t)];
% h2=area(xaxis,yaxis);
% % set(h2,'facecolor',LineColor,'edgecolor',LineColor)
% set(h2,'facecolor',LineColor,'edgecolor','None')
fill(xaxis,yaxis,LineColor,'edgecolor','None'); % modified 2016.10.11
alpha(Transparency);  % set the transparency

end