function cleaned_points = Remove_abn(points)
temp = diff(points(:,1));
cleaned_points(temp>5,:) = NaN;

[cleaned_points,TF] = fillmissing(cleaned_points,'linear');
