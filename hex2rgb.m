function rgb = hex2rgb(hex_colors)
%% Convert hex color codes to RGB values
% Xiong Xiao, 10/18/2024 @Shanghai
%%
if iscell(hex_colors) || isstring(hex_colors)  % Check if cell or string array
    num_colors = numel(hex_colors);  % Get the number of colors
    rgb = zeros(num_colors, 3);  % Preallocate for RGB values
    for i = 1:num_colors
        color = char(hex_colors(i));  % Convert to character array
        if color(1) == '#'
            color = color(2:end);  % Remove leading '#', if present
        end
        % Convert hex to RGB
        rgb(i, :) = [hex2dec(color(1:2)), hex2dec(color(3:4)), hex2dec(color(5:6))] / 255;
    end
else
    error('Input must be a cell array or string array.');
end

end
