function table_data = evaluate_data(experiment, results, figures_path, version_string)

table_data = cell(0,3);

if nargin > 1 && ~isempty(figures_path)
  mkdir(figures_path);
  savefigures = true;
else
  figures_path = [];
  savefigures = false;
end

if nargin < 4
  version_string ='';
end

if ~all(strcmp(experiment,{results.type}))
  error('incompatible experiment type');
end

% set control function
control_fun = str2func(['control_'  experiment]);

% get empirical data
[emp_level emp_deviation emp_explanation] = control_fun('level','deviation','explanation');

% target correct answer probability
target = control_fun('target');

% Get plot parameters
[plot_dim plot_xfactor plot_yfactor plot_xlog xlabel_string ylabel_string plot_xmarks plot_ymarks title_string] = control_fun( ...
  'dim', ...
  'xfactor', ...
  'yfactor', ...
  'xlog', ...
  'xlabel', ...
  'ylabel', ...
  'xmarks', ...
  'ymarks', ...
  'title' ...
  );

% Some basic input checks
assert(target > 0 && target < 1);
assert(length(size(emp_level)) == length(emp_explanation));
assert(length(size(emp_level)) == length(size(emp_deviation)));
assert(plot_dim <= length(size(emp_level)));

%% model data
subcondition = ccellfun(@(str,delim) regexp(str,delim,'split'),{results.subcondition},',');
subcondition = vertcat(subcondition{:});

if size(subcondition,2) == 1
  subcondition = [repmat({''},size(subcondition)) subcondition];
end

% plot dimension needs to be the last one
idx = 1:length(size(emp_level));
idx = [idx(idx ~= plot_dim), plot_dim];
subcondition = subcondition(:,idx);
emp_level = permute(emp_level,idx);
emp_deviation = permute(emp_deviation,idx);
emp_explanation = emp_explanation(idx);

ind_variable = cellfun(@str2num,subcondition(:,end));

[num_subconditions num_variables] = size(subcondition);
subconditions = cell(1,num_variables-1);
for iva=1:num_variables-1
  subconditions{iva} = unique(subcondition(:,iva));
end
dims = cellfun(@numel,subconditions);
num_combinations = prod(dims);
combinations = cell(num_combinations,num_variables-1);
idx = cell(1,num_variables-1);
for ico=1:num_combinations
  [idx{:}] = ind2sub(dims,ico);
  for iid=1:num_variables-1
    combinations{ico,iid} = subconditions{iid}{idx{iid}};
  end
end

for ico=1:num_combinations
  mask = true(num_subconditions,1);
  for iva=1:num_variables-1
    mask = mask & strcmp(subcondition(:,iva),combinations{ico,iva});
  end
  ind_variables = unique(sort(cellfun(@str2num,subcondition(mask,end))));
  num_ind_variables = length(ind_variables);

  if num_ind_variables == 0
    disp('skip: no independent variables');
    continue
  end

  subtitle_string = sprintf('%s',combinations{ico,:});

  % memory allocation
  level = zeros(1,num_ind_variables);
  deviation = zeros(1,num_ind_variables);
  info = cell(1,num_ind_variables);
  invalidrange = false(1,num_ind_variables);
  invalidtrain = false(1,num_ind_variables);
  
  for ide=1:num_ind_variables
    ind_variable_select = ind_variables(ide);
    subcondition_idx = find(mask & ind_variable == ind_variable_select);
    assert(numel(subcondition_idx) == 1,'Error identifying subcondition');

    train_levels = cellfun(@str2num, results(subcondition_idx).train_levels);
    test_levels = cellfun(@str2num, results(subcondition_idx).test_levels);
    total = results(subcondition_idx).total;
    correct = results(subcondition_idx).correct;

    if numel(unique(total(:))) > 1
      disp('Different number of test samples in conditions.');
    end

    pcorrect = correct./total;
    pcorrect_deviation = arrayfun(@estd,total,correct);

    % organize data
    [test_levels test_levels_idx] = sort(test_levels(:));
    [train_levels train_levels_idx] = sort(train_levels(:));
    pcorrect = pcorrect(train_levels_idx,test_levels_idx);
    pcorrect_deviation = pcorrect_deviation(train_levels_idx,test_levels_idx);

    % Find the psychometric function with the lowest SNR at threshold
    [values_threshold best_idx] = lowest_psy(test_levels, train_levels, pcorrect, pcorrect_deviation, target);

    level(ide) = values_threshold(best_idx,1);
    deviation(ide) = values_threshold(best_idx,2);
    info{ide} = num2str(train_levels(best_idx),'%.0f');
    
    if level(ide) > test_levels(end)
      level(ide) = test_levels(end);
      deviation(ide) = nan;
    elseif level(ide) < test_levels(1)
      level(ide) = test_levels(1);
      deviation(ide) = nan;
    end
    
    if level(ide) > test_levels(end-1)
      invalidrange(ide) = true;
    elseif level(ide) < test_levels(2)
      invalidrange(ide) = true;
    end

    if train_levels(best_idx) > train_levels(end-1)
      invalidtrain(ide) = true;
    elseif train_levels(best_idx) < train_levels(2)
      invalidtrain(ide) = true;
    end


    table_data(end+1,:) = {sprintf('%s_%s_%f',experiment,subtitle_string,ind_variable_select) [level(ide) deviation(ide)] info{ide}};

  end

  %% visualize data
  test_levels = unique(cellfun(@str2num,vertcat(results(mask).test_levels)));
  idx = cell(1,num_variables-1);
  for iid=1:num_variables-1
    idx{iid} = find(strcmp(emp_explanation{iid},combinations{ico,iid}));
  end

  x_emp = cellfun(@str2num,emp_explanation{end});
  y_emp = squeeze(emp_level(idx{:},:));
  e_emp = squeeze(emp_deviation(idx{:},:));
  x_mod = ind_variables;
  y_mod = level;
  e_mod = deviation;
  n_mod = info;
  if plot_xlog
    x_emp = log(x_emp);
    x_mod = log(x_mod);
  end
  x_range = setrange([x_emp(:); x_mod(:)],0.1);
  y_range = setrange([y_emp(:); test_levels(:)],0.1);

  figure('Position',[0 0 400 400],'Visible','off');
  h2 = plotdev(x_emp,y_emp,e_emp);
  hold on;
  h1 = plot(x_emp,y_emp,'-or');
  
  if ~isempty(plot_xmarks)
    for ima=1:length(plot_xmarks)
      plot([1 1].*plot_xmarks(ima),y_range,'k');
    end
  end

  if ~isempty(plot_ymarks)
    for ima=1:length(plot_ymarks)
      plot(x_range,[1 1].*plot_ymarks(ima),'k');
    end
  end

  h3 = errorbar(x_mod,y_mod,e_mod,'-ob');
  for j=1:length(x_mod)
    text(x_mod(j),y_mod(j),[' ' n_mod{j}],'Color',[.5 .5 1],'HorizontalAlignment','left');
  end

  h4 = plot(x_mod(invalidrange),y_mod(invalidrange),'xb');
  h5 = plot(x_mod(invalidtrain),y_mod(invalidtrain),'sb');

  xlabel(xlabel_string);
  ylabel(ylabel_string);

  xlim(x_range);
  ylim(y_range);
  set(gca,'YTick',test_levels);
  set(gca,'YTick',test_levels*plot_yfactor);
  set(gca,'XTick',x_mod);
  set(gca,'XTickLabel',ind_variables*plot_xfactor);
  grid on;

  legend([h1 h2 h3 h4 h5],{'Empirical','Empirical std','Model','Invalid (data)','Invalid (train)'},'location','northeast');
  h = text(x_mod(1),test_levels(1)*plot_yfactor,version_string);
  set(h,'Color',[1 1 1].*0.7);
  title([title_string ' ' subtitle_string]);

  if savefigures
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4 4]);
    print('-depsc2','-r300',[figures_path filesep experiment '_' subtitle_string '.eps']);
  end
end
end

