function [train_snrs, test_snrs, results] = read_data(results_file)
[train_condition, test_condition, utterance, correct, total] = read_ascii(results_file);

% Copyright (C) 2014-2016 Marc René Schädler

utterance = cellfun(@str2double,utterance);
num_words = unique(cellfun(@str2double,total));
assert(numel(num_words)==1,'different number of words per sentence');
percent_correct = cellfun(@str2double,correct)/num_words;

num_results = length(train_condition);

train_snr = zeros(1,num_results);
test_snr = zeros(1,num_results);

for i=1:num_results
  tmp_train_condition = train_condition{i};
  train_snr(i) = str2double(tmp_train_condition(end-2:end));
  tmp_test_condition = test_condition{i};
  test_snr(i) = str2double(tmp_test_condition(end-2:end));
end

train_snrs = sort(unique(train_snr));
test_snrs = sort(unique(test_snr));

num_train_snrs = length(train_snrs);
num_test_snrs = length(test_snrs);

results = cell(num_train_snrs,num_test_snrs);

for itr=1:num_train_snrs
  for ite=1:num_test_snrs
    mask = ((train_snr == train_snrs(itr)) & (test_snr == test_snrs(ite)));
    results(itr,ite) = {percent_correct(mask)};
  end
end
end
