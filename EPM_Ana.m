%% RTPP analysis using the Bosnai tracked data
% Hanfei Deng, 10/31/2022
clear,clc; close all
%%
tem = dir('*2025*.csv');
calibration_scale = 6.75/30; % 6.75cm/30pixel

% video:260 pixel width*273 pixel height
% arm:30 pixel
ClosedArm = 30/270 ;
outlier_percent = 0.5; % 1, 0.5, 0.1
exclude_outlier_flag = 1;
x_max_range = [20,260];
y_max_range = [20,270];
DistanceAveragePoint = 10;

%% Extract the data
TrackD_Sum = [];
FileName_Sum = [];

Closedline=[115,143];

for FileID = 1:numel(tem);
     filename = tem(FileID).name;
    A0 = readtable(filename);
    A0 = table2cell (A0);
    A = cell2mat(A0(:,2:4));

    Pos = A(:,[1,2]);
    Time = A(:,3)-A(1,3);
    [Pos,TF] = fillmissing(Pos,'linear'); % fill the missing data points

    %     Pos = A(:,[2,3]);
    %     Pos((isnan(Pos(:,2)) | isnan(Pos(:,1))),:) = [];
    if exclude_outlier_flag
        Pos((Pos(:,1)<x_max_range(1) | Pos(:,1)>x_max_range(2)),:) = NaN;
        Pos((Pos(:,2)<y_max_range(1) | Pos(:,2)>y_max_range(2)),:) = NaN;
    end

    [Pos,TF] = fillmissing(Pos,'linear'); % fill the missing data points

    % calculate the velocity and running distance
    Vx = gradient(Pos(:,1), Time);
    Vy = gradient(Pos(:,2), Time);
    Velocity = sqrt(Vx .^ 2 + Vy .^ 2);

    Distance0 = arrayfun(@(x) norm(Pos(x+1,:)-Pos(x,:)),(1:(size(Pos,1)-1))');
    Distance = [0;Distance0];

    TrackD = [Time,Pos,Velocity,Distance];
    TrackD(Velocity > prctile(Velocity,99)*2,:) = []; % remove the edge side effect
    ind = find(TrackD(:,1) < 600);
    TrackD = TrackD(ind,:);

    TrackD_Sum{FileID,1} = TrackD;
    FileName_Sum{FileID,1} = filename(1:end-4);

TrackD_Sum0 = cell2mat(TrackD_Sum(FileID,1));
x_min_max = [prctile(TrackD_Sum0(:,2),outlier_percent),prctile(TrackD_Sum0(:,2),100-outlier_percent)];
y_min_max = [prctile(TrackD_Sum0(:,3),outlier_percent),prctile(TrackD_Sum0(:,3),100-outlier_percent)];

figure('Position', [200 200 600 600],'Name','EPM');
hold on
line(TrackD_Sum0(:,2),TrackD_Sum0(:,3))
xline(x_min_max,'r--','LineWidth',2)
yline(y_min_max,'r--','LineWidth',2)
x1=Closedline(1);
x2=Closedline(2);
y1= y_min_max(1);
y2= y_min_max(2);
xline(x1,'g--','LineWidth',4)
xline(x2,'g--','LineWidth',4)
yline(y1,'g--','LineWidth',4)
yline(y2,'g--','LineWidth',4)
title(['Width (pixel) = ',num2str(x_min_max(2)-x_min_max(1))])
set(gca,'box','on')
axis tight; axis equal

%% Data analysis

ResultSum = [];

    %% load the csv data
    A = TrackD_Sum{FileID,1};

    Time = A(:,1);
    Pos = A(:,[2,3]);
    Velocity = A(:,4);
    Distance = A(:,5);

    %%
    figure('Position', [100 100 600 600],'Name','OpenField');
    % subplot(2,2,1)
    subplot('Position',[0.1300 0.3838 0.315 0.315])
    hold on
    line(Pos(:,1),Pos(:,2))
    xline(x1,'g--','LineWidth',4)
    xline(x2,'g--','LineWidth',4)
    yline(y1,'g--','LineWidth',4)
    yline(y2,'g--','LineWidth',4)
    title(FileName_Sum{FileID,1},'Interpreter','none');
    set(gca,'box','on','xlim',x_min_max,'ylim',y_min_max,'xtick',[],'ytick',[])
    axis equal; %axis tight;

    %% visualize the track data

    subplot('Position',[0.5703 0.3838 0.315 0.315]) % subplot(2,2,2)
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
    Velocity = Velocity*calibration_scale;
    Distance = Distance*calibration_scale;
    Distance(length(Distance)+1)=0;

    xv=[x1,x2,x2,x1,x1];
    yv=[y2,y2,y1,y1,y2];
    in=inpolygon(x,y,xv,yv);
    inx=[x(in)]';
    iny=[y(in)]';
    
    ClosedTrackD = A (in,[2:5]).*calibration_scale;
    OpenTrackD = A (not (in),[2:5]).*calibration_scale;
    
    
    ClosedVelocity = sum(ClosedTrackD(:,3)) / length(ClosedTrackD);
    OpenVelocity = sum(OpenTrackD(:,3)) / length (OpenTrackD);
    Velocity_mean = mean(Velocity);
 
    TimeTravel = [0;diff(Time)];
    ClosedTime = sum(TimeTravel(in));
    OpenTime = sum(TimeTravel(not(in)));

    Distance_sum = sumabs(Distance);
    CenterDistance = sumabs(ClosedTrackD(:,4));
    SurroundingDistance = sumabs(OpenTrackD(:,4));
    DistanceSum = [];
    DistanceSum(1) = 0;

    for i = 2:length(A)
        DistanceSum(i) = A(i,5) + DistanceSum(i - 1); 
    end
    
    Distance_minEach = [];
    for i = 0:9
        ind = find(60*i < A(:,1) &  A(:,1) < 60*(i+1)) ;
        Distance_minEach(i+1) = sumabs(Distance(ind,1));
    end
    

    ClosedPerc = (ClosedTime / (ClosedTime+OpenTime))*100;
    OpenPerc = (OpenTime / (ClosedTime+OpenTime))*100;
    
    ResultSum(FileID,:) = [ClosedPerc,OpenPerc,ClosedVelocity,OpenVelocity,CenterDistance,SurroundingDistance];
    ResultSum2(FileID,:) = [Velocity_mean,Distance_sum,OpenPerc];
    ResultSum3(FileID,:) = Distance_minEach;
    Distancetotal{FileID} = DistanceSum';

    
    %%
    subplot(3,3,7)
    X = categorical({'Closed','Open'});
    Y = [ClosedPerc,OpenPerc];
    b = bar (X, Y, 0.5);
    b.FaceColor = 'flat';
    b.CData(2,:) = [0.9290 0.6940 0.1250];
    ylabel('Time (%)');
    ylim([0,100]);

    subplot(3,3,8)
    X = categorical({'Closed','Open'});
    Y = [ClosedVelocity,OpenVelocity];
    b = bar (X, Y, 0.5);
    b.FaceColor = 'flat';
    b.CData(2,:) = [0.9290 0.6940 0.1250];
    ylabel('Velocity (cm/s)');
    ylim([0,inf]);

    subplot(3,3,9)
    X = categorical({'Closed','Open'});
    Y = [CenterDistance,SurroundingDistance];
    b = bar (X, Y, 0.5);
    b.FaceColor = 'flat';
    b.CData(2,:) = [0.9290 0.6940 0.1250];
    ylabel('Distance (cm)');
    ylim([0,inf]);

    print(gcf,[FileName_Sum{FileID,1},'_Track'],'-dpdf','-r0');
end



