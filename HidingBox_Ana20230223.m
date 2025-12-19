%% Hiding box analysis using the Bosnai tracked data
% Hanfei Deng, 10/31/2022, Xiong 02/21/2023
clear,clc; close all
%% read the file
tem_video = dir('*Video*2022*.csv');
tem_analog = dir('*Analog*2022*.csv');
tem_Bpod = dir('*_HidingBox_Laser*.mat');
calibration_scale = 63/371; % 63cm/371pixel

A_video = xlsread(tem_video.name);
A_analog = xlsread(tem_analog.name);

Trigger_ind = find(diff(A_analog)>1000)+1;
Trigger_ind = [1;Trigger_ind];
Trigger = A_analog(Trigger_ind)/1000; % laser

%% Extract the data
Pos = A_video(:,[2,3]);
Time = A_video(:,1)-A_video(1,1);
Area = A_video(:,[4]);
Trigger = Trigger-A_video(1,1);
% [Pos,TF] = fillmissing(Pos,'linear'); % fill the missing data points

% calculate the velocity
Vx = gradient(Pos(:,1), Time);
Vy = gradient(Pos(:,2), Time);
Velocity = sqrt(Vx .^ 2 + Vy .^ 2);

TrackD = [Time,Pos,Velocity];
% TrackD(Velocity > prctile(Velocity,99)*2,:) = []; % remove the edge side effect

%% Display the data
threshold_area = 300;
sel_hiding = (Area<threshold_area);
percent_hiding = sum(sel_hiding)./length(Area);

figure('Position',[200 200 1200 300]);
hold on
plot(Time, Area, 'k');
yline(threshold_area,'m','LineWidth',2);
xline(Trigger','b--','LineWidth',2)
legend('AreaSize','Threshold','Laser')
set(gca,'TickDir', 'out','box','off','FontSize',10);
xlabel('Time (s)')
ylabel('Area (pixels)')

title(['Hiding percent: ',num2str(percent_hiding)])

print('-dpng',[tem_Bpod.name(1:end-4),'_AreaTrace'])
set(gcf,'Render','Painter')
print('-depsc',[tem_Bpod.name(1:end-4),'_AreaTrace'])

%% Calculate the hiding lantency
HidingLatency = nan(1,length(Trigger));
for ii=1:length(Trigger)
    temp_ind = find(Area<threshold_area & Time>Trigger(ii),1,'first');
    HidingLatency(ii) = Time(temp_ind)-Trigger(ii);
end

disp(['Hiding latency (s): ', num2str(HidingLatency)])
save('HidingLatency','HidingLatency');

%% Laser info extracted from Bpod SessionData
load(tem_Bpod.name)

TrialTypes = SessionData.TrialTypes;
RawEvent = SessionData.RawEvents.Trial;
TrialStartTime_PC = SessionData.TrialStartTime_PC;

LaserTrial = [];
for ii=1:length(TrialTypes)

    trial_start = TrialStartTime_PC(ii)*3600*24; % convert to seconds

    laser_deliver = RawEvent{ii}.States.LaserDeliver(:,1);
    mannual_laser = RawEvent{ii}.States.MannualLaser(:,1);

    if ~isnan(laser_deliver)
        LaserTrial = [LaserTrial;laser_deliver+trial_start];
    end

    if ~isnan(mannual_laser)
        LaserTrial = [LaserTrial;mannual_laser+trial_start];
    end

end

LaserTrial2 = LaserTrial-TrialStartTime_PC(1)*3600*24;



