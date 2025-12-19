function [ht]=x_errbar(X,Y,Y_sem,cc)
%% error-bar plot
% X: 1:2:3
% Y: Data...
% Y_sem: sem

if nargin<4
    cc='k';
end

hold on
bar(X,Y,'FaceColor',cc,'EdgeColor','none','BarWidth',0.95);
ht = errorbar(X,Y,Y_sem,'Color',cc);
errorbarT(ht,0.5,2);

% xlim([X(1)-1 X(length(X))+1]);
% set(gca,'XTick',X); %


