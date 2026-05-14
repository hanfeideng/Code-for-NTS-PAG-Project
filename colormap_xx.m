function ColorMap = colormap_xx(num)
%% define colormaps for heatmap plots
%
%%
switch num
    case 1
        cMap0=hot(128);  cN=16;  cMap00=[linspace(0,cMap0(1,1),cN)',zeros(cN,2)];
        cMap = [cMap00;cMap0];
        cMap = fliplr(cMap); cMap2=cMap(1:112,:); cMap1=cMap0(1:112,:);
        cMap = [flipud(cMap2);cMap1];
        ColorMap = cMap;

    case 2 % 让激活更明显,for 小信号
        cN = 240;

        % 创建从浅蓝色到白色的渐变（前半部分）
        cMap1 = [linspace(0, 0.8, cN*2/3)',linspace(0.5, 0.92, cN*2/3)',ones(cN*2/3, 1)];
        cMap2 = [linspace(0.8, 1, cN*1/3)',linspace(0.92, 1, cN*1/3)',ones(cN*1/3, 1)];

        % 创建从白色到浅红色的渐变（后半部分）
        cMap3 = [ones(cN*1/5, 1),linspace(1, 0.75, cN*1/5)',linspace(1, 0.75, cN*1/5)'];
        cMap4 = [ones(cN*4/5, 1),linspace(0.75, 0, cN*4/5)',linspace(0.75, 0, cN*4/5)'];


        % 合并两部分颜色映射
        ColorMap = [cMap1; cMap2;cMap3; cMap4];

    case 3 % 让抑制更明显,for 小信号
        cN = 240;

        % 创建从浅蓝色到白色的渐变（前半部分）
        cMap1 = [linspace(0, 0.75, cN*3/4)',linspace(0.5, 0.92, cN*3/4)',ones(cN*3/4, 1)];
        cMap2 = [linspace(0.75, 1, cN*1/4)',linspace(0.92, 1, cN*1/4)',ones(cN*1/4, 1)];

        % 创建从白色到浅红色的渐变（后半部分）
        cMap3 = [ones(cN*1/5, 1),linspace(1, 0.75, cN*1/5)',linspace(1, 0.75, cN*1/5)'];
        cMap4 = [ones(cN*4/5, 1),linspace(0.75, 0, cN*4/5)',linspace(0.75, 0, cN*4/5)'];


        % 合并两部分颜色映射
        ColorMap = [cMap1; cMap2;cMap3; cMap4];

    case 4 % 让激活抑制都更不明显
        cN = 240;

        % 创建从浅蓝色到白色的渐变（前半部分）
        cMap1 = [linspace(0, 0.85, cN*2/3)',linspace(0.5, 0.92, cN*2/3)',ones(cN*2/3, 1)];
        cMap2 = [linspace(0.85, 1, cN*1/3)',linspace(0.92, 1, cN*1/3)',ones(cN*1/3, 1)];

        % 创建从白色到浅红色的渐变（后半部分）
        cMap3 = [ones(cN*1/3, 1),linspace(1, 0.9, cN*1/3)',linspace(1, 0.9, cN*1/3)'];
        cMap4 = [ones(cN*2/3, 1),linspace(0.9, 0, cN*2/3)',linspace(0.9, 0, cN*2/3)'];


        % 合并两部分颜色映射
        ColorMap = [cMap1; cMap2;cMap3; cMap4];

    case 5 % 让激活更明显,for 大信号
        cN = 120;

        % 创建从浅蓝色到白色的渐变（前半部分）
        cMap1 = [linspace(0, 0.85, cN*2/3)',linspace(0.5, 0.92, cN*2/3)',ones(cN*2/3, 1)];
        cMap2 = [linspace(0.85, 1, cN*1/3)',linspace(0.92, 1, cN*1/3)',ones(cN*1/3, 1)];

        % 创建从白色到浅红色的渐变（后半部分）
        cMap3 = [ones(cN*1/4, 1),linspace(1, 0.85, cN*1/4)',linspace(1, 0.85, cN*1/4)'];
        cMap4 = [ones(cN*3/4, 1),linspace(0.85, 0, cN*3/4)',linspace(0.85, 0, cN*3/4)'];

        % 合并两部分颜色映射
        ColorMap = [cMap1; cMap2;cMap3; cMap4];

    case 6 %让抑制更明显,for 大信号
        cN = 120;

        % 创建从浅蓝色到白色的渐变（前半部分）
        cMap1 = [linspace(0, 0.75, cN*2/3)',linspace(0.5, 0.92, cN*2/3)',ones(cN*2/3, 1)];
        cMap2 = [linspace(0.75, 1, cN*1/3)',linspace(0.92, 1, cN*1/3)',ones(cN*1/3, 1)];

        % 创建从白色到浅红色的渐变（后半部分）
        cMap3 = [ones(cN*1/3, 1),linspace(1, 0.9, cN*1/3)',linspace(1, 0.9, cN*1/3)'];
        cMap4 = [ones(cN*2/3, 1),linspace(0.9, 0, cN*2/3)',linspace(0.9, 0, cN*2/3)'];


        % 合并两部分颜色映射
        ColorMap = [cMap1; cMap2;cMap3; cMap4];

    otherwise
        R = ones(num,1);
        G = linspace(0,0.8,num)';
        B = zeros(num,1);
        ColorMap = [R,G,B];
end

end