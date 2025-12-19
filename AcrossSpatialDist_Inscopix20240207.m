%% Spatial distribution of different types of cells
clear,clc; close all
%%
tem = dir('NeuronSum*.mat');

Distance_AC = [];
Distance_AD = [];
Distance_BC = [];
Distance_BD = [];

%% load neuron data
tem_trace = dir('yuan*.csv');


%%
for FileN = 5
    s = importdata(tem_trace(FileN).name);
    s0 = s.data;
    s1 = s.textdata;
    s1 = convertCharsToStrings(s1(:,2));
    s1 = s1(2:end,:);
    neuron_ind = find(s1 == 'undecided');
    s2 = s0([neuron_ind],[4,5]);
    estCenter = s2;

    load(tem(FileN).name);
    time_interest_win = [2,6];
    data0 = cell2mat(NeuronSumNorm_mean(:,1));
    time = (0:(size(data0,2)-1))/5;
    
    auROC_matrix = zeros(size(NeuronSum,1),4);
    for k=1:size(NeuronSum,1)
        
        %%        
        % defined by sucrose responses
        data1 = NeuronSumNorm{k,1};
        d1 = data1(:,time>=time_interest_win(1) & time<=time_interest_win(2));
        d2 = data1(:,time<time_interest_win(1));
        data2 = NeuronSumNorm{k,2};
        d3 = data2(:,time>=time_interest_win(1) & time<=time_interest_win(2));
        d4 = data2(:,time<time_interest_win(1));
        
        d1 = mean(d1,2);
        d2 = mean(d2,2);
        d3 = mean(d3,2);
        d4 = mean(d4,2);
%         d2 = 0;
        
        p1 = ranksum(d1,d2);
        auROC_matrix(k,1) = mean(d1)-mean(d2);
        auROC_matrix(k,2) = (p1<0.05).*(mean(d1)-mean(d2));  
        p2 = ranksum(d3,d4);
        auROC_matrix(k,3) = mean(d3)-mean(d4);
        auROC_matrix(k,4) = (p2<0.05).*(mean(d3)-mean(d4));
        
    end
    
    % ind1 = find(auROC_matrix(:,2)>0 & auROC_matrix(:,4)<=0);
    % ind2 = find(auROC_matrix(:,4)>0 & auROC_matrix(:,2)<=0);
    ind1 = find(auROC_matrix(:,2)>0);
    ind2 = find(auROC_matrix(:,2)<0);
    ind3 = find(auROC_matrix(:,4)>0);
    ind4 = find(auROC_matrix(:,4)<0);
    
    if length(ind1)<2 || length(ind2)<2
        continue;
    end
    
    % calculate the distance
    % Coor = zeros(size(NeuronSum,1),2);
    % for k=1:size(NeuronSum,1)
    %     co = neuron.Coor{k};
    %     Coor(k,:) = mean(co,2)'.*2.58;
    % end
    Coor = estCenter.*2.58; % 2.58

    c1 = nchoosek(ind1,1);
    c2 = nchoosek(ind3,1);
    c = combvec(c1',c2')';
    ki = sortrows(c);
    Distance_AC0 = zeros(1,size(ki,1));
    for ii = 1:size(ki,1)
        Distance_AC0(ii) = norm(Coor(ki(ii,1),:)-Coor(ki(ii,2),:));
    end
    Distance_AC = [Distance_AC,Distance_AC0];
    
    
    c1 = nchoosek(ind1,1);
    c2 = nchoosek(ind4,1);
    c = combvec(c1',c2')';
    ki = sortrows(c);
    Distance_AD0 = zeros(1,size(ki,1));
    for ii = 1:size(ki,1)
        Distance_AD0(ii) = norm(Coor(ki(ii,1),:)-Coor(ki(ii,2),:));
    end
    Distance_AD = [Distance_AD,Distance_AD0];

    c1 = nchoosek(ind2,1);
    c2 = nchoosek(ind3,1);
    c = combvec(c1',c2')';
    ki = sortrows(c);
    Distance_BC0 = zeros(1,size(ki,1));
    for ii = 1:size(ki,1)
        Distance_BC0(ii) = norm(Coor(ki(ii,1),:)-Coor(ki(ii,2),:));
    end
    Distance_BC = [Distance_BC,Distance_BC0];
    
    c1 = nchoosek(ind2,1);
    c2 = nchoosek(ind4,1);
    c = combvec(c1',c2')';
    ki = sortrows(c);
    Distance_BD0 = zeros(1,size(ki,1));
    for ii = 1:size(ki,1)
        Distance_BD0(ii) = norm(Coor(ki(ii,1),:)-Coor(ki(ii,2),:));
    end
    Distance_BD = [Distance_BD,Distance_BD0];
    
    %%
        
end
%%
% [~,p1] = kstest2(Distance_A,Distance_B)
% 
% [~,p2] = kstest2(Distance_A,[Distance_All])
% 
% [~,p3] = kstest2(Distance_B,[Distance_All])
% 
Distance_AC(find(Distance_AC == 0)) = 1;
Distance_AD(find(Distance_AD == 0)) = 1;
Distance_BC(find(Distance_BC == 0)) = 1;
Distance_BD(find(Distance_BD == 0)) = 1;

%%
figure('Position', [200 50 900 400],'Name','DistancePlot','numbertitle','off')
subplot(1,2,1)
hold on

%
[f1,x1,bw] = ksdensity(Distance_AC,'Support','positive',...
    'Function','cdf');
plot(x1,f1,'k');
[f2,x2,bw] = ksdensity(Distance_AD,'Support','positive',...
    'Function','cdf');
plot(x2,f2,'g');
[f3,x3,bw] = ksdensity(Distance_BC,'Support','positive',...
    'Function','cdf');
plot(x3,f3,'r');
[f4,x4,bw] = ksdensity(Distance_BD,'Support','positive',...
    'Function','cdf');
plot(x4,f4,'m');

[h1, p1] = kstest2(f1, f2);
[h2, p2] = kstest2(f1, f3);
[h3, p3] = kstest2(f1, f4);
[h4, p4] = kstest2(f2, f3);
[h5, p5] = kstest2(f2, f4);
[h6, p6] = kstest2(f3, f4);

% p = cdfplot(Distance_All); p.Color = 'k';
% p = cdfplot(Distance_A); p.Color = 'g';
% p = cdfplot(Distance_B); p.Color = 'r';
xlim([0,600]);
xlabel('Pairwise neuron distance (um)'); ylabel('Cumulative probability');
set(gca,'TickDir','Out','box','off','FontSize',12);
legend('pinch+shock+','pinch+shock-','pinch-shock+','pinch-shock-')

%
% bin = 50; x = -bin/2:bin:600-bin/2;
% y1 = histc(Distance_All,x)./length(Distance_All);
% y2 = histc(Distance_A,x)./length(Distance_A);
% y3 = histc(Distance_B,x)./length(Distance_B);

pt = 100;
[y1,x1] = ksdensity(Distance_AC,'NumPoints',pt);
[y2,x2] = ksdensity(Distance_AD,'NumPoints',pt);
[y3,x3] = ksdensity(Distance_BC,'NumPoints',pt);
[y4,x4] = ksdensity(Distance_BD,'NumPoints',pt);

[h1, p1] = kstest2(Distance_AC, Distance_AD);
[h2, p2] = kstest2(Distance_AC, Distance_BC);
[h3, p3] = kstest2(Distance_AC, Distance_BD);
[h4, p4] = kstest2(Distance_AD, Distance_BC);
[h5, p5] = kstest2(Distance_AD, Distance_BD);
[h6, p6] = kstest2(Distance_BC, Distance_BD);

subplot(1,2,2)
hold on
plot(x1,y1*100,'k');
plot(x2,y2*100,'g');
plot(x3,y3*100,'r');
plot(x4,y4*100,'m');
xlim([0,600]);
xlabel('Pairwise neuron distance (um)'); ylabel('Probability');
set(gca,'TickDir','Out','box','off','FontSize',12);
legend('pinch+shock+','pinch+shock-','pinch-shock+','pinch-shock-');

%
print(gcf,['AcrossPairwiseNeuronDistancePlot'],'-dpdf','-r0');
% close;

% %%
% [~,p] = kstest2(Distance_AB,[Distance_A,Distance_B])
% 
% figure('Position', [200 50 900 400],'Name','DistancePlot','numbertitle','off')
% subplot(1,2,1)
% hold on
% 
% [f1,x1,bw] = ksdensity(Distance_AB,'Support','positive',...
%     'Function','cdf');
% plot(x1,f1,'k');
% [f2,x2,bw] = ksdensity([Distance_A,Distance_B],'Support','positive',...
%     'Function','cdf');
% plot(x2,f2,'g');
% xlim([0,600]);
% xlabel('Pairwise neuron distance (um)'); ylabel('Cumulative probability');
% set(gca,'TickDir','Out','box','off','FontSize',12);
% legend('Different','Same')
% 
% pt = 100;
% [y1,x1] = ksdensity(Distance_AB,'NumPoints',pt);
% [y2,x2] = ksdensity([Distance_A,Distance_B],'NumPoints',pt);
% subplot(1,2,2)
% hold on
% plot(x1,y1*100,'k');
% plot(x2,y2*100,'g');
% 
% xlim([0,600]);
% xlabel('Pairwise neuron distance (um)'); ylabel('Probability');
% set(gca,'TickDir','Out','box','off','FontSize',12);
% legend('Different','Same')
% 
% print(gcf,['PairwiseNeuronDistancePlot_SameDifferent'],'-dpdf','-r0');
% % close;
