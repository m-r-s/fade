function generate_conditions(target_dir, funname, classes, parameters, num_samples, conditions, seed, verbose)

mkdir(target_dir);

if ~is_octave()
  rng(seed, 'twister');
end

fhandle = str2func(funname);

num_conditions = length(conditions);
num_parameters = length(parameters);
num_classes = length(classes);

num_chars = ceil(log10(num_samples));
file_format = ['%' num2str(num_chars) '.0f'];

type_string = funname;

mkdir([target_dir filesep type_string]);

for ico=1:num_conditions
  condition_string = conditions{ico};
  if ~ischar(condition_string)
    condition_string = num2str(condition_string);
  end
  if verbose
    fprintf([funname ') Condition (%i/%i) %s:'],ico,num_conditions,condition_string);
  end
  mkdir([target_dir filesep type_string filesep condition_string]);
  for ipa=1:num_parameters
    parameter_string = parameters{ipa};
    if ~ischar(parameter_string)
      parameter_string = num2str(parameter_string);
    end
    if verbose
      fprintf(' %s',parameter_string);
    end
    % MUTEX to prevent concurrent threads to generate the same condition
    if unix(['mkdir "' target_dir filesep type_string filesep condition_string filesep parameter_string '" 2>/dev/null']) == 0
      for icl=1:num_classes
        class_string = classes{icl};
        if ~ischar(class_string)
          class_string = num2str(class_string);
        end
        for isa=1:num_samples
          file_string = ['_' num2str(isa,file_format)];
          filename = [target_dir filesep type_string filesep condition_string filesep parameter_string filesep class_string file_string '.wav'];
          [signal fs] = fhandle(classes{icl}, parameters{ipa}, conditions{ico});
          signal = [zeros(round(fs*0.1),size(signal,2));signal;zeros(round(fs*0.1),size(signal,2))];
          audiowrite(filename, signal, fs, 'BitsPerSample', 32);
          if ~verbose
            fprintf('.');
          end
        end
      end
    end
  end
  if verbose
    fprintf('\n');
  end
end
