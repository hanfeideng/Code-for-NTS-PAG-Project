function [h]=x_errbar_plot(X,Data,cc,method_average)
%% error-bar plot
% X: 1:2:3
% Y: Data{1}=Habituation; Data{2}=Predator; ...

if nargin < 4
    method_average = 'mean';
end

for k=1:numel(Data)
    if isequal(method_average,'median')
        y(k)=median(Data{k});
    else
        y(k)=mean(Data{k});
    end
    y_err(k)=std(Data{k})/sqrt(length(Data{k}));
end

if nargin<3
    cc={'b','m','r','k','g'};
end

figure
hold on
for k=1:numel(Data)
    bar(X(k),y(k),'FaceColor',cc{k},'EdgeColor','none','BarWidth',0.95);
    if y_err(k)>0
        h(k)=errorbar(X(k),y(k),y_err(k),'Color',cc{k});
        errorbarT(h(k),0.5,2)
    end
end

xlim([X(1)-1 X(length(X))+1]);
set(gca,'XTick',X); %
FigSet;

