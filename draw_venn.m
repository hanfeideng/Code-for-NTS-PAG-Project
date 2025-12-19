function draw_venn(Z1, Z2, Z3)
    
    % 计算半径（面积与元素个数成比例）
    r1 = sqrt(Z1/pi);
    r2 = sqrt(Z2/pi);
    
    % 处理特殊情况
    if Z3 == 0
        % 两圆相离
        d = r1 + r2 + 0.1*max(r1, r2);
        centerA = [-d/2, 0];
        centerB = [d/2, 0];
    elseif Z3 == min(Z1, Z2)
        % 完全包含的情况
        d = 0;  % 圆心重合
        centerA = [0, 0];
        centerB = [0, 0];
    else
        % 解方程求距离
        fun = @(d) intersection_area(r1, r2, d) - Z3;
        d = fsolve(fun, (r1 + r2)/2, optimoptions('fsolve', 'Display', 'off'));
        centerA = [-d/2, 0];
        centerB = [d/2, 0];
    end

    % 创建图形
    figure;
    hold on;
    
    % 绘制圆形（处理绘制顺序）
    theta = linspace(0, 2*pi, 100);
    [xA, yA] = deal(centerA(1) + r1*cos(theta), centerA(2) + r1*sin(theta));
    [xB, yB] = deal(centerB(1) + r2*cos(theta), centerB(2) + r2*sin(theta));
    
    if Z3 == min(Z1, Z2)
        % 处理完全包含的绘制顺序
        if Z1 <= Z2
            patch(xB, yB, [0.2 0.4 0.8], 'FaceAlpha', 0.3); % 先画大圆
            patch(xA, yA, [0.8 0.2 0.2], 'FaceAlpha', 0.3);
        else
            patch(xA, yA, [0.8 0.2 0.2], 'FaceAlpha', 0.3);
            patch(xB, yB, [0.2 0.4 0.8], 'FaceAlpha', 0.3);
        end
    else
        patch(xA, yA, [0.8 0.2 0.2], 'FaceAlpha', 0.3); % 红色
        patch(xB, yB, [0.2 0.4 0.8], 'FaceAlpha', 0.3); % 蓝色
    end
    
    % 添加文本标签
    label_positions = {
        [centerA(1)-r1/2, 0], Z1-Z3;    % 仅A区域
        [centerB(1)+r2/2, 0], Z2-Z3;    % 仅B区域
        [0, 0], Z3                      % 交集区域
    };
    
    for i = 1:3
        pos = label_positions{i,1};
        value = label_positions{i,2};
        if value > 0
            text(pos(1), pos(2), num2str(value),...
                'HorizontalAlignment','center',...
                'FontWeight','bold',...
                'FontSize',12);
        end
    end
    
    % 图形美化
    axis equal tight off
    xlim([min(centerA(1)-r1, centerB(1)-r2)-0.5,...
          max(centerA(1)+r1, centerB(1)+r2)+0.5]);
    ylim([min(-r1, -r2)-0.5, max(r1, r2)+0.5]);
    hold off;
end

% 辅助函数：计算两圆交集面积
function area = intersection_area(r1, r2, d)
    if d >= r1 + r2
        area = 0;
    elseif d <= abs(r1 - r2)
        area = pi * min(r1, r2)^2;
    else
        area = r1^2*acos((d^2 + r1^2 - r2^2)/(2*d*r1))...
             + r2^2*acos((d^2 + r2^2 - r1^2)/(2*d*r2))...
             - 0.5*sqrt((-d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(d+r1+r2));
    end
end