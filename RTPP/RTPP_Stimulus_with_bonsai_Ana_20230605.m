%% RTPP analysis using the Bosnai tracked data
% Hanfei Deng, 10/31/2022
clear,clc; close all
%%
tem = dir('*2023*.csv');
calibration_scale = 63/389; % 63cm/371pixel

outlier_percent = 0.5; % 1, 0.5, 0.1
exclude_outlier_flag = 0;
x_max_range = [20,500];
y_max_range = [50,200];

%% Extract the data
TrackD_Sum = [];
FileName_Sum = [];
B_Sum = [];
B = [];


for FileID = 1:numel(tem)
    % load the csv data
    filename = tem(FileID).name;
    try
        C = importdata(filename);
        A = C.data;
        B = C.textdata;
    catch
        % A0 = readtable(filename);
        % A0_left_ind = table2cell(A0(:,end));
        % A0_left_ind = matches(A2_left_ind,'True');
%         A0 = readtable(filename);
%         A0 = table2cell (A0);
%         A = cell2mat(A0);
    end

    Pos = A(:,[1,2]);
    Time = A(:,3)-A(1,3);
    [Pos,TF] = fillmissing(Pos,'linear'); % fill the missing data points

    %     Pos = A(:,[2,3]);
    %     Pos((isnan(Pos(:,2)) | isnan(Pos(:,1))),:) = [];
    if exclude_outlier_flag
        Pos((Pos(:,1)<x_max_range(1) | Pos(:,1)>x_max_range(2)),:) = NaN;
        Pos((Pos(:,2)<y_max_range(1) | Pos(:,2)>y_max_range(2)),:) = NaN;
    end

    % calculate the velocity and running distance
    Vx = gradient(Pos(:,1), Time);
    Vy = gradient(Pos(:,2), Time);
    Velocity = sqrt(Vx .^ 2 + Vy .^ 2);

    Distance0 = arrayfun(@(x) norm(Pos(x+1,:)-Pos(x,:)),(1:(size(Pos,1)-1))');
    Distance = [0;Distance0];

    TrackD = [Time,Pos,Velocity,Distance];
    ind = find(Velocity < prctile(Velocity,99)*2);
    TrackD = TrackD(ind,:); % remove the edge side effect
    B = B(ind);

    TrackD_Sum{FileID,1} = TrackD;
    B_Sum{FileID} = B;
    FileName_Sum{FileID,1} = filename(1:end-4);
end

TrackD_Sum0 = cell2mat(TrackD_Sum);
x_min_max = [prctile(TrackD_Sum0(:,2),outlier_percent),prctile(TrackD_Sum0(:,2),100-outlier_percent)];
y_min_max = [prctile(TrackD_Sum0(:,3),outlier_percent),prctile(TrackD_Sum0(:,3),100-outlier_percent)];

middle_threshold = (x_min_max(2)+x_min_max(1))/2;

figure('Position', [100 100 600 400],'Name','Real-time Place Preference');
hold on
line(TrackD_Sum0(:,2),TrackD_Sum0(:,3))
xline(x_min_max,'r--','LineWidth',2)
yline(y_min_max,'r--','LineWidth',2)
xline(middle_threshold,'g--','LineWidth',2)
title(['Width (pixel) = ',num2str(x_min_max(2)-x_min_max(1))])
set(gca,'box','on')
axis tight; axis equal

%% Data analysis

ResultSum = [];

for FileID = 2:numel(tem)
    %% load the csv data
     
    A = cell2mat(TrackD_Sum(FileID(:,1)));
    D = B_Sum{1,FileID};
    D = [convertCharsToStrings(D)];


    Time = A(:,1);
    Pos = A(:,[2,3]);
    Velocity = A(:,4);
    Distance = A(:,5);
    
    InOrNot = [];
    threshold = 2;
    InOrNot = DetectInOrNot(threshold,D);
    ind = diff(InOrNot);
    Out_To_In = find(ind==-1);
    if Out_To_In(1) < 1
        Out_To_In(1) = 1
    end

    if Out_To_In(end) > length(ind)
        Out_To_In(end) = length(ind);
    end
    In_To_Out = find(ind==1);
    if In_To_Out(end) > length(ind)
        In_To_Out(end) = length(ind);
    end


    %%
    figure('Position', [100 100 600 600],'Name','Real-time Place Preference');
    % subplot(2,2,1)
    subplot('Position',[0.1300 0.5838 0.315 0.115])
    hold on
    line(Pos(:,1),Pos(:,2));
    xline(middle_threshold,'g--','LineWidth',2)
    title(FileName_Sum{FileID,1},'Interpreter','none');
    set(gca,'box','on','xlim',x_min_max,'ylim',y_min_max,'xtick',[],'ytick',[])
    axis equal; %axis tight;

    %% visualize the track data

    subplot('Position',[0.5703 0.5838 0.315 0.115]) % subplot(2,2,2)
    x = Pos(:,1)';
    y = Pos(:,2)';
    %pts_x = linspace(0,max(x),ceil(max(x)/6));
    %pts_y = linspace(0,max(y),ceil(max(y)/6));
    pts_x = linspace(x_min_max(1),x_min_max(2),ceil((x_min_max(2)-x_min_max(1))/6));
    pts_y = linspace(y_min_max(1),y_min_max(2),ceil((y_min_max(2)-y_min_max(1))/6));
    N = histcounts2(y(:),x(:),pts_y,pts_x);
    [xG,yG] = meshgrid(-5:5);
    sigma = 2.5;
    g = exp(-xG.^2./(2.*sigma.^2)-yG.^2./(2.*sigma.^2));
    g = g./sum(g(:));
    density_s = conv2(N,g,'same');

    imagesc(pts_x,pts_y,density_s);
    set(gca,'box','on','xlim',x_min_max,'ylim',y_min_max,'ydir','normal','xtick',[],'ytick',[])
    axis equal; %axis tight;
    %     set(gca,'XLim',[0 rect(3)])
    %     set(gca,'YLim',[0 rect(4)])

    colormap('jet');
    density_all = density_s(:);
    %     caxis([0,prctile(density_all,99)])

    %% stats of distance and time
    Pos = Pos*calibration_scale;
    middle_threshold_scale = middle_threshold*calibration_scale;
    Velocity = Velocity*calibration_scale;
    Distance = Distance*calibration_scale;

    RightInd = (Pos(:,1)>=middle_threshold_scale);
    LeftInd = (Pos(:,1)<middle_threshold_scale);

    RightTrackD = A (RightInd,:);
    LeftTrackD = A (LeftInd,:);

    RightVelocity = sum(Velocity(RightInd)) / length(RightInd);
    LeftVelocity = sum(Velocity(LeftInd)) / length (LeftInd);

    TimeTravel = [0;diff(Time)];
    RightTime = sum(TimeTravel(RightInd));
    LeftTime = sum(TimeTravel(LeftInd));

    RightDistance = sumabs(Distance(RightInd));
    LeftDistance = sumabs(Distance(LeftInd));

    RightPerc = RightTime / (RightTime+LeftTime);
    LeftPerc = LeftTime / (RightTime+LeftTime);

    Out_To_In_Velocity = sum(Velocity(Out_To_In))/length(Out_To_In);
    In_To_Out_Velocity = sum(Velocity(In_To_Out))/length(In_To_Out);
    Out_To_In_Number = length(Velocity(Out_To_In));
    In_To_Out_Number = length(Velocity(In_To_Out));

    ResultSum = [ResultSum;[RightPerc,LeftPerc,RightVelocity,LeftVelocity,RightDistance,LeftDistance,Out_To_In_Velocity,In_To_Out_Velocity,Out_To_In_Number,In_To_Out_Number]];

    %%
    subplot(3,5,11)
    X = categorical({'Right','Left'});
    Y = [RightPerc,LeftPerc];
    bar (X, Y, 0.5);
    ylabel('Time (%)');
    ylim([0,1]);

    subplot(3,5,12)
    X = categorical({'Right','Left'});
    Y = [RightVelocity,LeftVelocity];
    bar (X, Y, 0.5);
    ylabel('Velocity (cm/s)');
    %ylim([0,1]);

    subplot(3,5,13)
    X = categorical({'Right','Left'});
    Y = [RightDistance,LeftDistance];
    bar (X, Y, 0.5);
    ylabel('Distance (cm)');

    subplot(3,5,14)
    X = categorical({'OToI','IToO'});
    Y = [Out_To_In_Velocity,In_To_Out_Velocity];
    bar (X, Y, 0.5);
    ylabel('EnterVelocity (cm/s)');

    subplot(3,5,15)
    X = categorical({'OToI','IToO'});
    Y = [Out_To_In_Number,In_To_Out_Number];
    bar (X, Y, 0.5);
    ylabel('Number');

    %% Save the results and plot

    print(gcf,[FileName_Sum{FileID,1},'_Track'],'-dpdf','-r0');

end

save('Results');


function Left_To_Right = DetectLeftToRight(LeftOrRight)
ind = diff(LeftOrRight);
ind_Left_To_Right = find(ind==2)+1;
Out_To_In = [];
for i = 1:length(ind_Left_To_Right)
    temp = find(ind(ind_Left_To_Right(i):end)~=0);
    if ind(ind_Left_To_Right(i)+temp(1)-1) == -1
        Left_To_Right = [Left_To_Right;ind_Left_To_Right(i)+9];
    end
end
end

function Right_To_Left = DetectRightToLeft(LeftOrRight)
ind = diff(LeftOrRight);
ind_Right_To_Left = find(ind==-2)+1;
Right_To_Left = [];
for i = 2:length(ind_Right_To_Left)
    temp = find(ind(1:ind_Right_To_Left(i))~=0);
    if ind(temp(end)) == 1
        Right_To_Left = [Right_To_Left;ind_Right_To_Left(i)+9];
    end
end
end

function InOrNot = DetectInOrNot(threshold,data)
% Ind is 1, means right; 0 means left; 2 means undecided.
ind = ones(length(data),1)*2;
temp = ones(length(data),1);
StimulusInd = find(data == 'True' );
NonStimulusInd = find(data == 'False' );
temp(StimulusInd) = 1;
temp(NonStimulusInd) = 0;

for i = 1:length(temp)-threshold + 1
    WhetherIn = sum(temp(i:i-1+threshold))==threshold;      % If WhetherRight is 1, means mice inside
    if WhetherIn==1
        ind(i) = 1 ;   % if all points in Stimulus side
    end

    WhetherOut = sum(temp(i:i-1+threshold))==0;      % If WhetherIn is 0, means mice outside
    if WhetherOut==1
        ind(i) = 0 ;   % if all points in NonStimulus side
    end
end
InOrNot = ind;
end



