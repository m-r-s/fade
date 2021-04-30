function [signal fs] = SM(type, variable, condition)
% usage: [signal fs] = SM(type, variable, condition)

# Author 2014-2021 Marc René Schädler

% check input
assert(numel(type)==1);
assert(isnumeric(type));
assert(any(type==[0 1]));
assert(numel(variable)==1);
assert(isnumeric(variable));
assert(ischar(condition));

% parse condition string
condition = regexp(condition,',','split');
[masker_level tone_frequency] = condition{:};
masker_level = str2num(masker_level);
tone_frequency = str2num(tone_frequency);
assert(numel(masker_level)==1);
assert(isnumeric(masker_level));
assert(numel(tone_frequency)==1);
assert(isnumeric(tone_frequency));

% set parameters
fs = 16000; % Hz
reference_level = 130; % dB SPL ~ 0 dB RMS
stimulus_duration = 0.500; % s
tone_duration = 0.220; % s
tone_level = variable; % dB SPL
tone_flank_duration = 0.010; %s
masker_duration = 0.220; % s
masker_frequencies = [961 1040]; % Hz
masker_flank_duration = 0.010; % s

[signal fs] = toneinnoise( ...
  type, ...
  fs, ...
  reference_level, ...
  stimulus_duration, ...
  tone_duration, ...
  tone_level, ...
  tone_frequency, ...
  tone_flank_duration, ...
  masker_duration, ...
  masker_level, ...
  masker_frequencies, ...
  masker_flank_duration ...
  );

end

