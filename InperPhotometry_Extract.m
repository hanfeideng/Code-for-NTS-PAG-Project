%% Read Inper photometry data
clear,clc; close all
%% Extract the photometry signal
FileFodler = pwd;
tem_photometry = dir('*Camera*.csv');
tem_photometry_trigger = dir('*Marker.csv');

A0 = readtable(tem_photometry.name,'VariableNamingRule','preserve');
VariableNames = A0.Properties.VariableNames

signal_t = seconds(A0.Time);

signal_410{1} = A0{:,'ROI-1_sig_410'};
signal_470{1} = A0{:,'ROI-1_sig_470'};
signal_410{2} = A0{:,'ROI-2_sig_410'};
signal_470{2} = A0{:,'ROI-2_sig_470'};
Input_DIO_1_Bpod = A0{:,'Input_DIO-1-Bpod'};

trigger_evt0 = Input_DIO_1_Bpod;
trigger_evt_ind = find(diff(trigger_evt0)>0)+1;
trigger_evt = signal_t(trigger_evt_ind);

channel = numel(signal_470);

%% load Bpod behavior data
tem_bpod = dir('*GoNoGo*.mat');
load(tem_bpod.name);

Bpod_TrialStartTimeStamp = SessionData.TrialStartTimestamp; % Bpod event
TrialTypes = SessionData.TrialTypes;

shit_t1 = diff(trigger_evt);
shit_t2 = diff(Bpod_TrialStartTimeStamp');

if length(trigger_evt)>length(TrialTypes)
    trigger_evt = trigger_evt(1:length(TrialTypes));
else
    TrialTypes = TrialTypes(1:length(trigger_evt));
end

%% fit signal curve
fit_ind = 1000;
for k=1:channel
    signal_470_fit0{k} = smoothdata(signal_470{k},'gaussian',fit_ind);
    signal_470_fit{k} = (signal_470{k}-signal_470_fit0{k})./signal_470_fit0{k};
    signal_410_fit0{k} = smoothdata(signal_410{k},'gaussian',fit_ind);
    signal_410_fit{k} = (signal_410{k}-signal_410_fit0{k})./signal_410_fit0{k};
end

%% plot corrected raw signal
FileName = tem_bpod.name(1:end-4);

for k=1:channel

    figure('position',[200,200,1200,400])
    h = sgtitle([FileName,'; channel ',num2str(k)]);set(h,'interpreter','none','fontsize',10);

    subplot(4,1,1)
    hold on
    plot(signal_t,signal_410{k},'g')
    ylabel('Raw 410','FontSize',10);
    subplot(4,1,2)
    plot(signal_t,signal_410_fit{k},'k')
    ylabel('Corrected 410','FontSize',10);
    subplot(4,1,3)
    hold on
    plot(signal_t,signal_470{k},'g')
    ylabel('Raw 470','FontSize',10);
    subplot(4,1,4)
    plot(signal_t,signal_470_fit{k},'k')
    ylabel('Corrected 470','FontSize',10);

end

%% cue onset 470 signal index
evt_start_time_match_ind = zeros(length(trigger_evt),1);
for ii = 1:length(trigger_evt)
    [~,idx]=min(abs(signal_t-trigger_evt(ii)));%
    evt_start_time_match_ind(ii) = idx(1);
end

%%
freq = round(1./mean(diff(signal_t)));
pre = 2; post = 6;

pre_bin_num = round(pre*freq);
post_bin_num = round(post*freq);

for k=1:channel
    beh_signal0 = arrayfun(@(x) (signal_470_fit{k}((x-pre_bin_num):(x+post_bin_num))),evt_start_time_match_ind','UniformOutput',false);
    beh_signal0 = cell2mat(beh_signal0);
    beh_signal{k} = beh_signal0';
end

beh_F470_t = arrayfun(@(x)(signal_t((x-pre_bin_num):(x+post_bin_num)) - signal_t(x)),evt_start_time_match_ind','UniformOutput',false);
beh_F470_t = cell2mat(beh_F470_t);
beh_F470_t = mean(beh_F470_t',1);

%% SessionData.TrialTypes 0 = punish; 1 = reward
trial_type = unique(TrialTypes);
% trial_type = [-1,2];
beh_F = cell(1,length(trial_type));

for mm=1:channel
    for kk=1:length(trial_type)
        beh_F{mm,kk} = beh_signal{mm}(TrialTypes==trial_type(kk),:);
    end
end

%% Color Map
cMap0=hot(64); cMap0=cMap0(1:48,:); cN=4;  cMap00=[linspace(0,cMap0(1,1),cN)',zeros(cN,2)];
cMap0 = [cMap00;cMap0]; cMap1=cMap0; cMap1(:,2)=cMap1(:,2); cMap2 = fliplr(cMap0);
cMap = [flipud(cMap2);cMap1];
ColorMap = cMap;

%% visulize the photometry data
time = beh_F470_t; % ylim = [-15 15];

TypeName = {'No-go Trial','Go Trial'};
subplottitleName = {'Cue--Nothing','Cue--Reward'};

for mm=1:channel


    %% Plot the PSTH
    figure('position',[100,100,600,400])
    h = sgtitle(['Go/no-go Task; channel ',num2str(mm)]);set(h,'interpreter','none','fontsize',12);

    for j = 1:size(beh_F,2)
        % z-score the data
        baseline = mean(beh_F{mm,j}(:,time<0),2);
        baseline_mean = mean(baseline);
        baseline_std = std(baseline);
        beh_F{mm,j} = (beh_F{mm,j}-baseline_mean)/baseline_std; % zscore of deltaF/F

        % plot align heatmap
        subplot(2,2,j)%% 2 types
        title(subplottitleName{j},'interpreter','none','fontsize',12);
        hold on
        if  isempty(beh_F{mm,j})
            continue
        else
            imagesc(time,1:size(beh_F{mm,j},1),beh_F{mm,j}); colormap(ColorMap);
            caxis([-6 6]); % colorbar('location','East')
            % colorbar('location','East')
            ylabel(TypeName{j},'FontSize',8);
            set(gca,'TickDir','out','xlim',[-pre,post],'XTick',-pre:1:post,...
                'ylim',[0.5,size(beh_F{mm,j},1)+0.5],'FontSize',12);%
            %画起始竖线
            plot([0 0],[0.5 size(beh_F{mm,j},1)+0.5],'w','linewidth',1.5);%size(beh_F,1) trial个数
            plot([2 2],[0.5 size(beh_F{mm,j},1)+0.5],'w','linewidth',1.5);
        end

        %plot align curve
        h(j) = subplot(2,2,j+2);
        hold on

        if  isempty(beh_F{mm,j})
            continue
        elseif size(beh_F{mm,j},1) == 1 %% 判断行为是否只有一次
            plot(time,beh_F{mm,j});
        else
            beh_F470mean = mean(beh_F{mm,j});% mean(A) 返回包含每列均值的行向量
            beh_Fsem = std(beh_F{mm,j})./sqrt(size(beh_F{mm,j},1));%标准误  % std(beh_F470)默认按列算
            U_sem = beh_F470mean + beh_Fsem;
            L_sem = beh_F470mean - beh_Fsem;
            plot(time,beh_F470mean,'linewidth',1.5);%%%
            %画sem
            yaxis=[U_sem,fliplr(L_sem)];
            xaxis=[time,fliplr(time)];
            fill(xaxis,yaxis,[0.8 0.8 1],'edgecolor','None');
            alpha(0.4);
        end
        xlabel('Time(s)','FontSize',12)
        ylabel([TypeName(j),'dF(zscore)'],'FontSize',12)
        % 画起始竖线
        xline(0,'k--','linewidth',1.5);
        xline(2,'b--','linewidth',1.5);
        set(gca,'TickDir','out','xtick',-pre:1:post,'xlim',[-pre,post],'FontSize',12,'box','off');
    end
    linkaxes([h(1) h(2)],'xy');

    %%
    saveas(gcf,['GoNoGo_PSTH_Plot_channel',num2str(mm),'.jpg']);
    saveas(gcf,['GoNoGo_PSTH_Plot_channel',num2str(mm),'.fig'])
    saveas(gcf,['GoNoGo_PSTH_Plot_channel',num2str(mm),'.eps']);

end

