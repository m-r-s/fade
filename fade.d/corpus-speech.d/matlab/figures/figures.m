function figures(results_file, varargin)
% usage figures(results_file, figures_path, version_string, scoring, target)

% Copyright (C) 2014-2016 Marc René Schädler

if nargin > 1 && ~isempty(varargin{1})
  figures_path = varargin{1};
  mkdir(figures_path);
  savefigures = true;
else
  figures_path = [];
  savefigures = false;
end

if nargin > 2 && ~isempty(varargin{2})
  version_string = varargin{2};
else
  version_string = '';
end

if nargin > 3 && ~isempty(varargin{3})
  scoring = varargin{3};
else
  scoring = 'word';
end

if nargin > 4 && ~isempty(varargin{4})
  target = varargin{4};
  if ischar(target)
    target = str2num(target);
  end
else
  target = 0.5;
end

disp(['Scoring: '  scoring]);
disp(['Target: '  num2str(target)]);

% change default font type
set (0, 'defaultaxesfontname', 'LiberationSans');
set (0, 'defaulttextfontname', 'LiberationSans');

table_data = {};

% read and interpret the data file
switch scoring
  case 'word'
    total_idx = 1;
    correct_idx = 2;
  case 'sentence'
    total_idx = 3;
    correct_idx = 4;
  case 'weighted'
    total_idx = 3;
    correct_idx = 5;
  otherwise
    scoring_tmp = strsplit(scoring,',');
    total_idx = str2num(scoring_tmp{1});
    correct_idx = str2num(scoring_tmp{2});
end

data = cell(1,max(total_idx,correct_idx));
[train_condition test_condition data{:}] = read_ascii(results_file);

total = data{total_idx};
correct = data{correct_idx};

train_condition = regexp(train_condition.', '_', 'split');
train_condition = vertcat(train_condition{:});
test_condition = regexp(test_condition.', '_', 'split');
test_condition = vertcat(test_condition{:});
total = cellfun(@str2double,total);
correct = cellfun(@str2double,correct);

exptypes = unique(train_condition(:,1));
train_snr = cellfun(@str2double,regexp(train_condition(:,2),'[+-][0-9]+$','match'));
test_snr =  cellfun(@str2double,regexp(test_condition(:,2),'[+-][0-9]+$','match'));

for iex=1:length(exptypes)
  exptype = exptypes{iex};
  disp(['Trying to visualize data for experiment: '  exptype]);
  expmask = strcmp(train_condition(:,1), exptype);

  train_snrs = sort(unique(train_snr(expmask)));
  test_snrs = sort(unique(test_snr(expmask)));
  num_train_snrs = length(train_snrs);
  num_test_snrs = length(test_snrs);

  totaltmp = zeros(num_train_snrs, num_test_snrs);
  correcttmp = zeros(num_train_snrs, num_test_snrs);

  for itr=1:num_train_snrs
    for ite=1:num_test_snrs
      masktmp = train_snrs(itr)==train_snr & test_snrs(ite)==test_snr & expmask;
      if ~isempty(total(masktmp))
        totaltmp(itr,ite) = total(masktmp);
      end
      if ~isempty(correct(masktmp))
        correcttmp(itr,ite) = correct(masktmp);
      end
    end
  end

  if numel(unique(totaltmp(:))) > 1
    disp('Different number of test samples in conditions.');
  end

  pcorrect = correcttmp./totaltmp;
  pcorrect_deviation = arrayfun(@estd,totaltmp,correcttmp);

  if ~any(pcorrect(:) > target)
    disp('skip: no result exceeds the target treshold');
    continue
  end

  % Find the sane psychometric function with the lowest SNR at threshold
  [values_threshold best_idx] = lowest_psy(test_snrs, train_snrs, pcorrect, pcorrect_deviation, target);

  best_srt = values_threshold(best_idx,1);
  best_srt_deviation = values_threshold(best_idx,2);
  best_slope = values_threshold(best_idx,3);
  best_slope_deviation = values_threshold(best_idx,4);
  best_train_snr = train_snrs(best_idx);
  train_dependency = interp2(test_snrs, train_snrs, pcorrect, best_srt, train_snrs);
  train_dependency_dev = interp2(test_snrs, train_snrs, pcorrect_deviation, best_srt, train_snrs);
  table_data(end+1,:) = {exptype [best_srt best_srt_deviation] 100.*[best_slope best_slope_deviation] best_train_snr};

  if ~isfinite(best_srt)
    disp('skip figure: no finite SRT');
    continue
  end

  %% Visualize data
  figure('Position',[0 0 600 600],'Visible','on');
  subplot = @(m,n,p) axes('Position',subposition(m,n,p,[0.125 0.125],[0.035 0.05],[1 1]));

  subplot(2,2,1);
  colormap('gray');
  imagesc(test_snrs,train_snrs,pcorrect*100,[0,100]); axis xy;
  hold on;
  for mark_rate=20:10:90
    line_width = 1;
    if any(mark_rate == [50])
      line_width = 2;
    end
    contour(test_snrs,train_snrs,pcorrect.*100,[1 1].*mark_rate,'linewidth',line_width,'linecolor',[1 1 1]);
  end
  plot(best_srt,best_train_snr,'xb','markersize',10,'linewidth',1.5);
  set(gca,'XTick',test_snrs);
  set(gca,'YTick',train_snrs);
  xlim(setrange(test_snrs,0.1));
  ylim(setrange(train_snrs,0.1));
  grid on;
  xlabel([exptype ': Test SNR [dB]']);
  ylabel('Train SNR [dB]');
  h = text(test_snrs(1),train_snrs(1),version_string);
  set(h,'Color',[1 1 1].*0.5);

  subplot(2,2,2);
  colormap('gray');
  plotdev(test_snrs,pcorrect(best_idx,:).*100,pcorrect_deviation(best_idx,:)*100,0.85*ones(1,3));
  hold on;
  plot(test_snrs,pcorrect(best_idx,:).*100,'k');

  for mark_rate=[10 50 80]
    plot([-100 100],[1 1].*mark_rate,'-.k');
    hold on;
  end

  h = line(best_srt+[-2 2].*best_srt_deviation, [1 1].*target*100);
  set(h,'color','blue');
  h = line([1 1].*(best_srt+2*best_srt_deviation), target*100 + [-1 1].*1);
  set(h,'color','blue');
  h = line([1 1].*(best_srt-2*best_srt_deviation), target*100 + [-1 1].*1);
  set(h,'color','blue');
  plot(best_srt,target*100,'xb','markersize',10,'linewidth',1.5);
  set(gca,'XTick',test_snrs);
  set(gca,'YTick',0:10:100);
  xlim(setrange(test_snrs,0.1));
  ylim([0 100]);
  grid on;
  xlabel([exptype ': Test SNR [dB]']);
  ylabel('Word recognition rate [%]');
  snr_text = ['\@ ' sprintf('%4.1f',best_train_snr) ' dB'];
  srt_text = [sprintf('%4.1f',best_srt) '+-' sprintf('%4.2f',best_srt_deviation) ' dB'];
  slope_text = [sprintf('%4.1f',best_slope*100) '+-' sprintf('%4.2f',best_slope_deviation*100) ' %/dB'];
  text(test_snrs(1),74,snr_text);
  text(test_snrs(1),94,srt_text);
  text(test_snrs(1),84,slope_text);

  subplot(2,2,3);
  colormap('gray');
  plotdev(train_snrs,values_threshold(:,1),values_threshold(:,2),0.85*ones(1,3));
  hold on;
  plot(train_snrs,values_threshold(:,1),'k');

  plot(train_snrs(best_idx),best_srt,'xb','markersize',10,'linewidth',1.5);
  set(gca,'XTick',train_snrs);
  set(gca,'YTick',test_snrs);
  xlim(setrange(test_snrs,0.1));
  ylim(setrange(train_snrs,0.1));
  grid on;
  xlabel([exptype ': Train SNR [dB]']);
  ylabel('SRT [dB]');

  subplot(2,2,4);
  colormap('gray');
  plotdev(train_snrs,values_threshold(:,3)*100,values_threshold(:,4)*100,0.85*ones(1,3));
  hold on;
  plot(train_snrs,values_threshold(:,3)*100,'k');

  plot(train_snrs(best_idx),best_slope*100,'xb','markersize',10,'linewidth',1.5);
  set(gca,'XTick',train_snrs);
  min_step = min(diff(train_snrs));
  set(gca,'YTick',0:3:100/min_step);
  xlim(setrange(test_snrs,0.1));
  ylim(setrange([0 100/min_step],0.1));
  grid on;
  xlabel([exptype ': Train SNR [dB]']);
  ylabel('Slope at SRT [%/dB]');

  if savefigures
    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 6 6].*1.4);
    print('-depsc2','-r300',[figures_path filesep exptype '.eps']);
  end
end

if savefigures
  eval_strings{1} = 'NOISE SRT SRT_dev SLOPE SLOPE_dev SRT_train';
  for ire=1:size(table_data,1)
    [noise_string srt slope info] = table_data{ire,:};
    srt_string = sprintf('%.2f %.2f',srt(1),srt(2));
    slope_string = sprintf('%.2f %.2f',slope(1),slope(2));
    info_string = sprintf('%.0f',info);
    eval_strings{1+ire} = [noise_string ' ' srt_string ' ' slope_string ' ' info_string];
  end

  fid = fopen([figures_path filesep 'table.txt'],'w');
  for i=1:length(eval_strings)
    fprintf(fid,'%s\n',eval_strings{i});
  end
  fclose(fid);
end


end

function out = padd(in,l,s,d)
switch d
  case 'l'
    out = [repmat(s,1,l-size(in,2)) in];
  case 'r'
    out = [in repmat(s,1,l-size(in,2))];
  otherwise
    out = in;
end
end
