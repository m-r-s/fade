function figures(results_file, figures_path, version_string)

if nargin > 1 && ~isempty(figures_path)
  mkdir(figures_path);
  savefigures = true;
else
  figures_path = [];
  savefigures = false;
end

if nargin < 3
  version_string ='';
end

% change default font type
set (0, 'defaultaxesfontname', 'LiberationSans');
set (0, 'defaulttextfontname', 'LiberationSans');

table = {};

% read and interpret the data file
[train_condition test_condition total correct] = read_ascii(results_file);
train_condition = regexp(train_condition.', '_', 'split');
train_condition = vertcat(train_condition{:});
test_condition = regexp(test_condition.', '_', 'split');
test_condition = vertcat(test_condition{:});
train_experiment = train_condition(:,1);
train_subcondition = train_condition(:,2);
train_level = train_condition(:,3);
test_experiment = test_condition(:,1);
test_subcondition = test_condition(:,2);
test_level = test_condition(:,3);
total = cellfun(@str2double,total);
correct = cellfun(@str2double,correct);

experiments = unique(test_experiment);
table_data = cell(0,3);

for iex=1:length(experiments)
  results = struct('type',{},'subcondition',{},'train_levels',{},'test_levels',{},'total',{},'correct',{});
  count = 0;

  experiment = experiments{iex};
  disp(['Trying to visualize data for experiment: '  experiment]);
  train_experiment_mask = strcmp(train_experiment, experiment);
  test_experiment_mask = strcmp(test_experiment, experiment);

  subconditions = unique(test_subcondition(test_experiment_mask));
  for isc=1:length(subconditions)
    count = count + 1;
    subcondition = subconditions{isc};
    train_subcondition_mask = train_experiment_mask & strcmp(train_subcondition, subcondition);
    test_subcondition_mask = test_experiment_mask & strcmp(test_subcondition, subcondition);
    train_levels = unique(train_level(train_subcondition_mask));
    test_levels = unique(test_level(test_subcondition_mask));

    results(count).type = experiment;
    results(count).subcondition = subcondition;
    results(count).train_levels = train_levels;
    results(count).test_levels = test_levels;

    tmp_total = zeros(length(train_levels),length(test_levels));
    tmp_correct = zeros(length(train_levels),length(test_levels));
    for ite=1:length(test_levels)
      test_level_mask = test_subcondition_mask & strcmp(test_level,test_levels(ite));
      for itr=1:length(train_levels)
        train_level_mask = train_subcondition_mask & strcmp(train_level,train_levels(itr));
        idx = find(test_level_mask & train_level_mask);
        if isempty (idx) || numel(idx) > 1
            error('empty or ambiguous test condition');
        end
        tmp_total(itr,ite) = total(idx);
        tmp_correct(itr,ite) = correct(idx);
      end
    end
    results(count).total = tmp_total;
    results(count).correct = tmp_correct;
  end

  if ~isempty(results)
    table_data_tmp = evaluate_data(experiment, results, figures_path, version_string);
    table_data = [table_data; table_data_tmp];
  end
end

% Generate table
if savefigures
  eval_strings = {};
  num_table_entries = size(table_data,1);

  eval_strings{1} = 'CONDITION LEVEL LEVEL_dev LEVEL_train';
  for ite=1:num_table_entries
    [type_string level info_string] = table_data{ite,:};
    level_string = [num2str(level(1),'%.2f') ' ' num2str(level(2),'%.2f')];
    eval_strings{end+1} = [type_string ' ' level_string ' ' info_string];
  end

  fid = fopen([figures_path filesep 'table.txt'],'w');
  for i=1:length(eval_strings)
    fprintf(fid,'%s\n',eval_strings{i});
  end
  fclose(fid);
end

end

