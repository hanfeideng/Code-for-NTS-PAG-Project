function FigSet(fig)
%% Set the parameters of plotting the figures

%%
if nargin < 1 || isempty(fig)
    fig = gcf;
end

%%
% xlim([-2 1]);
% ylim([0 size(ZZZ,1)]);
% set(gca,'YTick',1:4,'YTickLabel',{'I','II','III','IV'});

% xlabel('Time from waiting tone onset (s)','FontSize',16);
% ylabel('Neuron #','FontSize',16);
%%
% set(fig,'Renderer','painters')
% print('-dtiff','1','-opengl','-r1500');

%%
set(gca,'YDir','normal');

set(gca,'box','off');
set(gca,'layer','top');
set(gca,'TickDir','out','TickLength',[0.015 0.015]);
set(gca,'FontSize',16,'LineWidth',1);
set(fig,'units','inches');
set(fig,'Position',[5.6, 2, 5.6, 4.2]);

