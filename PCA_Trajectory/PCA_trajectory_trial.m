%% plot the neural trajectories in different trials
clear,clc; close all
%% load the data
tem = dir('NeuronSum_*.mat');
cc = [hex2rgb({'999999'});hex2rgb({'CE0665'});hex2rgb({'F26522'})];%% 灰色，浅粉，深粉

NeuronSum_All = [];
NeuronSum_mean_All = [];

for k = 1:numel(tem)
    load(tem(k).name);
    NeuronSum_All = [NeuronSum_All;NeuronSumNorm];
    NeuronSum_mean_All = [NeuronSum_mean_All;NeuronSumNorm_mean];
end

A = NeuronSum_All(:,1);
B = NeuronSum_All(:,2);
C = NeuronSum_All(:,3);
D = NeuronSum_All(:,4);

trial_num1 = size(A{1},1);
trial_num2 = size(B{1},1);
trial_num3 = size(C{1},1);
trial_num4 = size(D{1},1);

pre = 2; post = 8;
time = -pre:1/5:post;
time = time(1:end-1);

pre = 2; post = 18;
time_long = -pre:1/5:post;
time_long = time_long(1:end-1);

%%
neuron_del = [177 144];
if ~isempty(neuron_del)
    A(neuron_del,:) = [];
    B(neuron_del,:) = [];
    C(neuron_del,:) = [];
    D(neuron_del,:) = [];
end

%%
EDistanceSum = [];
neuron_num = size(A,1);

%% load the data for each trial type
A_trial = [];
for ii_a = 1:trial_num1    
    temp = cellfun(@(x) x(ii_a,:), A,'UniformOutput',false);
    A_trial{ii_a} = cell2mat(temp);
end

B_trial = [];
for ii_a = 1:trial_num2    
    temp = cellfun(@(x) x(ii_a,:), B,'UniformOutput',false);
    B_trial{ii_a} = cell2mat(temp);
end

C_trial = [];
for ii_a = 1:trial_num3    
    temp = cellfun(@(x) x(ii_a,:), C,'UniformOutput',false);
    C_trial{ii_a} = cell2mat(temp);
end

D_trial = [];
for ii_a = 1:trial_num4    
    temp = cellfun(@(x) x(ii_a,:), D,'UniformOutput',false);
    D_trial{ii_a} = cell2mat(temp);
end

%% load the data and pre-process the data
temp = cellfun(@(x) mean(x,1),A,'UniformOutput',false);
data1 = cell2mat(temp);

temp = cellfun(@(x) mean(x,1),B,'UniformOutput',false);
data2 = cell2mat(temp);

temp = cellfun(@(x) mean(x,1),C,'UniformOutput',false);
data3 = cell2mat(temp);

temp = cellfun(@(x) mean(x,1),D,'UniformOutput',false);
data4 = cell2mat(temp);

%% PCA (reduce the neuron number)
% data_for_pca = [data1(:, time<=6),data2(:, time<=6)];
% data_for_pca = [data1(:, time<=6),data2(:, time<=6),data3(:, time_long<=16),data4(:, time_long<=16)];
% data_for_pca = [data1(:, time<=4),data2(:, time<=2)];
% data_for_pca = [data1(:, time<=4)];
% data_for_pca = [data2(:, time<=2)];
data_for_pca = [data1(:, time<=5),data2(:, time<=5)];

[coeff,score,latent,~,explainedVar] = pca(data_for_pca');

A_trial_pca = [];
for ii_a = 1:trial_num1
    A_trial_pca{ii_a} = A_trial{ii_a}'*coeff;
end

B_trial_pca = [];
for ii_a = 1:trial_num2
    B_trial_pca{ii_a} = B_trial{ii_a}'*coeff;
end

C_trial_pca = [];
for ii_a = 1:trial_num3
    C_trial_pca{ii_a} = C_trial{ii_a}'*coeff;
end

D_trial_pca = [];
for ii_a = 1:trial_num4
    D_trial_pca{ii_a} = D_trial{ii_a}'*coeff;
end

tt_sel = (time<=6);
tt_long_sel = (time_long<=16);

%% 3D plot
figure

hold on
for ii_a = 1:trial_num4
    pca_yy = D_trial_pca{ii_a}(:,1:2);
    plot3(smooth(pca_yy(tt_sel,1),5),smooth(pca_yy(tt_sel,2),5),time_long(tt_sel),'Color',cc(1,:), 'LineWidth', 1);
    plot3(pca_yy(time_long==0,1),pca_yy(time_long==0,2),time_long(time_long==0),'ko','MarkerSize',5,'MarkerFaceColor','k','MarkerEdgeColor','None');
    plot3(pca_yy(time_long==6,1),pca_yy(time_long==6,2),time_long(time_long==6),'ko','MarkerSize',5,'MarkerFaceColor',cc(1,:),'MarkerEdgeColor','None');
    
end

hold on
for ii_a = 1:trial_num2
    pca_yy = B_trial_pca{ii_a}(:,1:2);
    plot3(smooth(pca_yy(tt_sel,1),5),smooth(pca_yy(tt_sel,2),5),time(tt_sel),'Color',cc(2,:), 'LineWidth', 1);
    plot3(pca_yy(time==0,1),pca_yy(time==0,2),time(time==0),'ko','MarkerSize',5,'MarkerFaceColor','k','MarkerEdgeColor','None');
    plot3(pca_yy(time==6,1),pca_yy(time==6,2),time(time==6),'ko','MarkerSize',5,'MarkerFaceColor',cc(2,:),'MarkerEdgeColor','None');
    
end

hold on
for ii_a = 1:trial_num1
    pca_yy = A_trial_pca{ii_a}(:,1:2);
    plot3(smooth(pca_yy(tt_sel,1),5),smooth(pca_yy(tt_sel,2),5),time(tt_sel),'Color',cc(3,:), 'LineWidth', 1);
    plot3(pca_yy(time==0,1),pca_yy(time==0,2),time(time==0),'ko','MarkerSize',5,'MarkerFaceColor','k','MarkerEdgeColor','None');
    plot3(pca_yy(time==6,1),pca_yy(time==6,2),time(time==6),'ko','MarkerSize',5,'MarkerFaceColor',cc(3,:),'MarkerEdgeColor','None');
    
end

grid on
view([48.295454545454561,14.372560975609757])
legend('hot','','','shock','','','pinch','','');
xlabel('PC 1'); ylabel('PC 2'); zlabel('Time (s)'); 
% set(gca,'TickDir','Out','box','off');
set(gca,'TickDir', 'out','xlim',[-10,40],'ylim',[-10,30],'FontSize', 16,'box','on');
% axis tight;
% print(gcf,['Ac_PCA_trial_along_time_new'],'-dpdf','-r0');

