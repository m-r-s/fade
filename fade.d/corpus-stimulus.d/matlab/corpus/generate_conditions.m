function generate_conditions(target_dir, funname, classes, parameters, num_samples, conditions, seed)

mkdir(target_dir);

if is_octave
  rand('twister', seed);
else
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

count = 0;
total = num_conditions*num_parameters*num_classes*num_samples;
fprintf('A total of %i files will be generated.\n',total);
t0 = 0;
tic;
for ico=1:num_conditions
  condition_string = conditions{ico};
  if ~ischar(condition_string)
    condition_string = num2str(condition_string);
  end
  fprintf([funname ') Condition (%i/%i) %s:'],ico,num_conditions,condition_string);
  mkdir([target_dir filesep type_string filesep condition_string]);
  for ipa=1:num_parameters
    parameter_string = parameters{ipa};
    if ~ischar(parameter_string)
      parameter_string = num2str(parameter_string);
    end
    fprintf(' %s',parameter_string);
    mkdir([target_dir filesep type_string filesep condition_string filesep parameter_string]);
    for icl=1:num_classes
      class_string = classes{icl};
      if ~ischar(class_string)
        class_string = num2str(class_string);
      end
      for isa=1:num_samples
        file_string = ['_' num2str(isa,file_format)];
        filename = [target_dir filesep type_string filesep condition_string filesep parameter_string filesep class_string file_string '.wav'];
        [signal fs] = fhandle(classes{icl}, parameters{ipa}, conditions{ico});
        audiowrite(filename, signal, fs, 'BitsPerSample', 32);
        count = count + 1;
      end
    end
  end
  fprintf('\n');
  if toc - t0 > 60
    fprintf('%i files have been written so far. Approximately %i minutes remaining.\n',count,ceil(toc/count*(total-count)/60));
    t0 = toc;
  end
end
