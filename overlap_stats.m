function [pval_high,pval_low] = overlap_stats(all_n,vn1,vn2,vn12)
%% to determine the statistical significance of overlap
% Xiong Xiao, 2019/05/17

%%
RepeatN = 5000;
n1n2_sum = zeros(RepeatN,1);

for k=1:RepeatN
    n1 = datasample(1:all_n,vn1,'Replace',false);
    n2 = datasample(1:all_n,vn2,'Replace',false);
    n1n2 = intersect(n1,n2);
    n1n2_sum(k) = length(n1n2);
end

pval_high = sum(n1n2_sum>vn12)/RepeatN;
pval_low = sum(n1n2_sum<vn12)/RepeatN;

%%
% figure
% hist(n1n2_sum)

end