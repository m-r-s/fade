function [signal, fs] = toneinnoise(type, fs, reference_level, stimulus_duration, tone_duration, tone_level, tone_frequency, tone_flank_duration, masker_duration, masker_level, masker_frequencies, masker_flank_duration)
%usage [signal, fs] = toneinnoise(type, fs, reference_level, stimulus_duration, tone_duration, tone_level, tone_frequency, tone_flank_duration, masker_duration, masker_level, masker_frequencies, masker_flank_duration)

# Author 2014-2021 Marc René Schädler

% calculate derived parameters
stimulus_samples = round(fs.*stimulus_duration);
tone_samples = round(fs.*tone_duration);
tone_offset = round(fs.*(stimulus_duration-tone_duration)./2);
tone_flank_samples = round(fs.*tone_flank_duration);
masker_samples = round(fs.*masker_duration);
masker_offset = round(fs.*(stimulus_duration-masker_duration)./2);
masker_flank_samples = round(fs.*masker_flank_duration);

% initialize signal with -30 dB SPL spectrum level white noise
signal = randn(stimulus_samples,1);
signal = normalize(signal, -30-reference_level) .* sqrt(fs./2);

% generate and add noise masker
masker = bandpassnoise(masker_samples, masker_frequencies./fs);
masker = normalize(masker, masker_level-reference_level);
masker = flank(masker, masker_flank_samples, masker_flank_samples);
signal(1+masker_offset:masker_samples+masker_offset) = ...
  signal(1+masker_offset:masker_samples+masker_offset) + masker;

switch type
  case 0 
    % add no tone
  case 1
    % add tone
    tone = sinewavephase(tone_samples, tone_frequency./fs, 0);
    tone = normalize(tone, tone_level-reference_level);
    tone = flank(tone, tone_flank_samples, tone_flank_samples);
    signal(1+tone_offset:tone_samples+tone_offset) = ...
      signal(1+tone_offset:tone_samples+tone_offset) + tone;
end

end

