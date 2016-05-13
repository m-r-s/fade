function [level deviation info] = find_level_at_threshold(experiment, target, num_samples)
train_levels = experiment.train_levels;
test_levels = cellfun(@str2num, experiment.test_levels);

values = ccellfun(@bootstrap, num_samples,experiment.data, @mean);

values_mean = cellfun(@mean,values);
values_std = cellfun(@std,values);

train_thresholds = nan(size(train_levels));
train_thresholds_std = nan(size(train_levels));

[junk sort_idx] = sort(test_levels);

for itr=1:length(train_levels)
  x = test_levels(sort_idx);
  y = values_mean(itr,sort_idx);
  yt = target;
  y_std = values_std(itr,sort_idx);
  [train_thresholds(itr) train_thresholds_std(itr)] = find_threshold(x,y,yt,y_std);
end

[junk select] = min(train_thresholds+2*train_thresholds_std);

level = train_thresholds(select);
deviation = train_thresholds_std(select);
info = train_levels{select};

if level > max(test_levels)
  level = max(test_levels);
  deviation = nan;
elseif level < min(test_levels)
  level = min(test_levels);
  deviation = nan;
end
end