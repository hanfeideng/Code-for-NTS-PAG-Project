%% Read Inper photometry data
clear,clc; close all
%% Extract the photometry signal
FileFodler = pwd;
tem_photometry = dir('*Camera*.csv');
tem_photometry_trigger = dir('*Marker.csv');

A0 = readtable(tem_photometry.name,'VariableNamingRule','preserve');
VariableNames = A0.Properties.VariableNames

signal_t = seconds(A0.Time);

signal_410{1} = A0{:,'ROI-2-_sig_410'};
signal_470{1} = A0{:,'ROI-2-_sig_470'};
Input_DIO_1_Bpod = A0{:,'Input_DIO-1-bpod'};

trigger_evt0 = Input_DIO_1_Bpod;
trigger_evt_ind = find(diff(trigger_evt0)>0)+1;
trigger_evt = signal_t(trigger_evt_ind);

channel = 1;

% trial_sel{1} = []; % all trials
trial_sel{1} = []; % selected trials,eg: 5:20

%% load Bpod behavior data
tem_bpod = dir('*Naive_US*.mat');
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

US_deliver_time = SessionData.RawEvents.Trial{1,1}.States.USDeliver(1);
trigger_evt = trigger_evt; % no need to add US_deliver_time as shock was delivered at the same time as the signal sent to Inper

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

    subplot(2,1,1)
    hold on
    plot(signal_t,signal_470{k},'g')
    ylabel('Raw 470','FontSize',10);
    subplot(2,1,2)
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
pre = 4; post = 12;

for ii = 1:length(trigger_evt)-1
    evt_start_time_match_ind1(ii) = evt_start_time_match_ind(ii+1,1) - 19 * freq;
end
evt_start_time_match_ind1 = evt_start_time_match_ind1';

pre_bin_num = round(pre*freq);
post_bin_num = round(post*freq);

for k=1:channel
    beh_signal0 = arrayfun(@(x) (signal_470_fit{k}((x-pre_bin_num):(x+post_bin_num))),evt_start_time_match_ind','UniformOutput',false);
    beh_signal0 = cell2mat(beh_signal0);
    beh_signal{k} = beh_signal0';
end

for k=1:channel
    beh_signal1 = arrayfun(@(x) (signal_470_fit{k}((x-pre_bin_num):(x+post_bin_num))),evt_start_time_match_ind1','UniformOutput',false);
    beh_signal1 = cell2mat(beh_signal1);
    beh_signal2{k} = beh_signal1';
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
        beh_F{mm,kk+1} = beh_signal2{mm};

        if ~isempty(trial_sel{kk})
            beh_F{mm,kk} = beh_F{mm,kk}(trial_sel{kk},:);
        end
    end
end

%% Color Map
cMap0=hot(64); cMap0=cMap0(1:48,:); cN=4;  cMap00=[linspace(0,cMap0(1,1),cN)',zeros(cN,2)];
cMap0 = [cMap00;cMap0]; cMap1=cMap0; cMap1(:,2)=cMap1(:,2); cMap2 = fliplr(cMap0);
cMap = [flipud(cMap2);cMap1];
ColorMap = cMap;
ColorMap = colormap_xx(1);

cc = linspecer(length(trial_type));

%% visulize the photometry data (470nm)
time = beh_F470_t; % ylim = [-15 15];
AUC_Sum = [];
PEAK_Sum = [];

subplottitleName = {'Laser On','Sham'};

for mm=channel


    %% Plot the PSTH
    figure('position',[100,100,900,600])
    sgtitle(['470nm; channel ',num2str(mm)],'interpreter','none','fontsize',12);
    h = [];

    for j = 1:2
        % z-score the data
        baseline = mean(beh_F{mm,j}(:,time<0),2);
        baseline_mean = mean(baseline);
        baseline_std = std(baseline);
        beh_F{mm,j} = (beh_F{mm,j}-baseline_mean)/baseline_std; % zscore of deltaF/F
        beh_F{mm,j} = beh_F{mm,j}(:,time>-2);
        time1 = time(time>-2);

        % plot align heatmap
        subplot(2,2,j)%% 2 types
        title(subplottitleName{j},'interpreter','none','fontsize',12);
        hold on

        imagesc(time1,1:size(beh_F{mm,j},1),beh_F{mm,j}); colormap(ColorMap);
        caxis([-6 6]); % colorbar('location','East')
        % colorbar('location','East')
        ylabel('Trial #','FontSize',8);
        set(gca,'TickDir','out','xlim',[-2,12],'XTick',-2:1:12,...
            'ylim',[0.5,size(beh_F{mm,j},1)+0.5],'FontSize',12);
        xline([0],'w','linewidth',1.5); % 画起始竖线
        colorbar;

        %plot align curve
        h(j) = subplot(2,2,j+2);
        hold on

        beh_F470mean = mean(beh_F{mm,j});% mean(A) 返回包含每列均值的行向量
        beh_Fsem = std(beh_F{mm,j})./sqrt(size(beh_F{mm,j},1));%标准误  % std(beh_F470)默认按列算
        yy_smooth = movmean(beh_F470mean,5); % smoothing the curve (change the value as needed)
        yy_sem_smooth = movmean(beh_Fsem,5); % smoothing the curve (change the value as needed)
        AreaPlot(time1,yy_smooth,yy_sem_smooth,cc(kk,:),0.4,1);

        xlabel('Time (s)','FontSize',12)
        ylabel(['dF(zscore)'],'FontSize',12)
        xline(0,'k--','linewidth',1.5); % 画起始竖线
        set(gca,'TickDir','out','xtick',-2:1:12,'ylim',[-10,10],'ytick',-10:2:10,'xlim',[-2,12],'FontSize',12,'box','off');
    end

    linkaxes([h],'xy');
    %%
    set(gcf,'Render','Painter')
    saveas(gcf,['US_PSTH_NewPlot',num2str(mm),'.jpg']);
    saveas(gcf,['US_PSTH_NewPlot',num2str(mm),'.pdf'])
    print('-depsc',['US_PSTH_NewPlot_470channel',num2str(mm)])


    for jj = 1:2
        sample_data = beh_F{mm,jj};
        sample_data_smooth = movmean(sample_data,20);

        beh_F470mean = mean(sample_data);% mean(A) 返回包含每列均值的行向量
        ROC = beh_F470mean(pre_bin_num:pre_bin_num+5*freq);
        peak_ind = find(abs(ROC) == max(abs(ROC)));
        peak = ROC(peak_ind);
        beh_Fsem = std(sample_data)./sqrt(size(sample_data,1));%标准误  % std(beh_F470)默认按列算
        yy_smooth = movmean(beh_F470mean,20); % smoothing the curve (change the value as needed)
        yy_sem_smooth = movmean(beh_Fsem,5); % smoothing the curve (change the value as needed)
        xx = 1:length(ROC);
        AUC = trapz(xx,ROC)./freq;
        AUC_Sum = [AUC_Sum;AUC];
        PEAK_Sum = [PEAK_Sum;peak];
    end
end


save(['Data_',FileName(1:6)],'beh_F','time');
writematrix(AUC_Sum,'AUC_Sum.csv');
writematrix(PEAK_Sum,'PEAK_Sum.csv');

%% =======================================================================


