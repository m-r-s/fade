function [signal fs] = TIN(type, variable, condition)
% usage: [signal fs] = TIN(type, variable, condition)

# Author 2014-2021 Marc René Schädler

% check input
assert(numel(type)==1);
assert(isnumeric(type));
assert(any(type==[0 1]));
assert(numel(variable)==1);
assert(isnumeric(variable));
assert(numel(condition)==1);
assert(isnumeric(condition));

% set parameters
fs = 16000; % Hz
reference_level = 130; % dB SPL ~ 0 dB RMS
stimulus_duration = 0.500; % s
tone_duration = condition; % s
tone_level = variable; % dB SPL
tone_frequency = 2000; % Hz
tone_flank_duration = 0.0025; %s
masker_duration = 0.500; % s
masker_level = 65; % dB SPL
masker_frequencies = [20 5000]; % Hz
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

