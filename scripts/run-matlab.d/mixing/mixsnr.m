function mixsnr(speech_dir, noise_dir, hrir_speech_dir, hrir_noise_dir, target_dir, snrs, num_samples, sil, seed)
% usage: mixsnr(speech_dir, noise_dir, hrir_speech_dir, hrir_noise_dir, target_dir, snrs, num_samples, sil, seed)
%
% Load wav files in "speech_dir" and "noise_dir".
% Padd the speech signal with "sil" seconds of silence.
% Mix the speech signals with random portions of the noise signals.
% until "num_samples" recordings are reached for each SNR in "snr".
% Optionally process speech and noise signals with impulse responses in "hrir_speech_dir" and "hrir_noise_dir", respectively.
% Save the results to target_dir.
% A random "seed" must be provided.
% The output is structured for use with FADE.
%

% Copyright (C) 2014-2016 Marc René Schädler

if is_octave
  rand('twister', seed);
else
  rng(seed, 'twister');
end

asciifill = '01234567899';
min_noise_duration = 60; % seconds
crossfade_overlap = 0.25; % seconds

speech_files = dir([speech_dir filesep '*.wav']);
speech_files = {speech_files.name};
[~, shuffle_idx] = sort(rand(1,numel(speech_files)));
speech_files = speech_files(shuffle_idx);

noise_files = dir([noise_dir filesep '*.wav']);
noise_files = {noise_files.name};

hrir_speech_files = dir([hrir_speech_dir filesep '*.wav']);
hrir_speech_files = {hrir_speech_files.name};
[~, shuffle_idx] = sort(rand(1,numel(hrir_speech_files)));
hrir_speech_files = hrir_speech_files(shuffle_idx);

hrir_noise_files = dir([hrir_noise_dir filesep '*.wav']);
hrir_noise_files = {hrir_noise_files.name};
[~, shuffle_idx] = sort(rand(1,numel(hrir_noise_files)));
hrir_noise_files = hrir_noise_files(shuffle_idx);

num_speech_files = length(speech_files);
num_noise_files = length(noise_files);
num_hrir_speech_files = length(hrir_speech_files);
num_hrir_noise_files = length(hrir_noise_files);
num_snrs = length(snrs);

speech = cell(size(speech_files));
noise = cell(size(noise_files));
hrir_speech = cell(size(hrir_speech_files));
hrir_noise = cell(size(hrir_noise_files));

total = num_noise_files.*num_snrs.*num_samples;
fprintf('a total of %i files will be generated\n', total);
fprintf('random seed is: %i\n', seed);
fprintf('prepend/append speech signal with %.2f/%.2f s of silence\n', sil(1), sil(2));

% Load noise files
fprintf('load %i noise files\n', num_noise_files);
for i=1:num_noise_files
  [signal, fs] = audioread([noise_dir filesep noise_files{i}]);
  fprintf('loaded noise file ''%s'' with average level %.2f dB\n', noise_files{i}, 10*log10(mean(signal(:).^2)));
  assert(checkfs(fs),'different sample frequencies!');
  % extend noise to minimum length
  if size(signal,1) < fs.*min_noise_duration
    fprintf('extend noise signal to %i seconds duration\n', min_noise_duration);
    signal = crossfade_extend(signal, round(fs.*crossfade_overlap), ceil(fs.*min_noise_duration));
  end
  noise{i} = signal;
  [~, noise_files{i}] = fileparts(noise_files{i});
  if ~isempty(strfind(noise_files{i}, '_'))
    fprintf('underscore (_) in ''%s'' will be replaced with dash (-)\n', noise_files{i});
    noise_files{i} = strrep(noise_files{i},'_','-');
  end
end

% Load speech files
fprintf('load %i speech files\n', num_speech_files);
for i=1:num_speech_files
  [signal, fs] = audioread([speech_dir filesep speech_files{i}]);
  fprintf('loaded speech file ''%s'' with average level %.2f dB\n', speech_files{i}, 10*log10(mean(signal(:).^2)));
  assert(checkfs(fs), 'different sample frequencies!');
  speech{i} = [zeros(round(fs*sil(1)),size(signal,2)); signal; zeros(round(fs*sil(2)),size(signal,2))];
  [~, speech_files{i}] = fileparts(speech_files{i});
end

% Load HRIRs für speech samples
fprintf('load %i HRIRs files (impulse responses) for speech samples\n', num_hrir_speech_files);
for i=1:num_hrir_speech_files
  [signal, fs] = audioread([hrir_speech_dir filesep hrir_speech_files{i}]);
  fprintf('loaded HRIR file ''%s'' for speech samples with level (%.2f+65) dB\n', hrir_speech_files{i}, 10*log10(sum(signal(:).^2)));
  signal = signal .* 10.^(65./20);
  assert(checkfs(fs),'different sample frequencies!');
  hrir_speech{i} = signal;
  [~, hrir_speech_files{i}] = fileparts(hrir_speech_files{i});
end

% Load HRIRs für noise samples
fprintf('load %i HRIRs  files (impulse responses) for noise samples\n', num_hrir_noise_files);
for i=1:num_hrir_noise_files
  [signal, fs] = audioread([hrir_noise_dir filesep hrir_noise_files{i}]);
  fprintf('loaded HRIR file ''%s'' for noise samples with level (%.2f+65) dB\n', hrir_noise_files{i}, 10*log10(sum(signal(:).^2)));
  signal = signal .* 10.^(65./20);
  assert(checkfs(fs),'different sample frequencies!');
  hrir_noise{i} = signal;
  [~, hrir_noise_files{i}] = fileparts(hrir_noise_files{i});
end

% Shuffle HRIR files for speech samples (if any)
if num_hrir_speech_files > 0
  fprintf('speech samples will be processed with HRIR\n');
  num_hrir_speech_rep = ceil(num_samples./num_hrir_speech_files);
  hrir_speech_idx = repmat(1:num_hrir_speech_files,1,num_hrir_speech_rep);
  [~, shuffle_idx] = sort(rand(size(hrir_speech_idx)));
  hrir_speech_idx = hrir_speech_idx(shuffle_idx);
else
  fprintf('signals will not be processed with HRIR\n');
  hrir_speech_idx = [];
end

% Shuffle HRIR files for noise samples (if any)
if num_hrir_noise_files > 0
  fprintf('noise samples will be processed with HRIR\n');
  num_hrir_noise_rep = ceil(num_samples./num_hrir_noise_files);
  hrir_noise_idx = repmat(1:num_hrir_noise_files,1,num_hrir_noise_rep);
  [~, shuffle_idx] = sort(rand(size(hrir_noise_idx)));
  hrir_noise_idx = hrir_noise_idx(shuffle_idx);
else
  fprintf('signals will not be processed with HRIR\n');
  hrir_noise_idx = [];
end

fs = checkfs;
t0 = 0;
count = 0;

fprintf('sample frequency is %.2f Hz\n',fs);
tic;
for inoi=1:num_noise_files
  noise_signal = noise{inoi};
  noise_dir = [target_dir filesep noise_files{inoi}];
  if ~exist(noise_dir,'dir');
    mkdir(noise_dir);
  end
  for isnr=1:num_snrs
    snr = snrs(isnr);
    snr_dir = [noise_dir filesep sprintf('snr%+03i',snr)];
    if ~exist(snr_dir,'dir');
      mkdir(snr_dir);
    end
    for isam=1:num_samples
      rep = floor((isam-1)./num_speech_files);
      ispe = isam - num_speech_files.*rep;
      sample_dir = [snr_dir filesep sprintf('rep%02d',rep)];
      if ~exist(sample_dir,'dir');
        mkdir(sample_dir);
      end
      filename = [sample_dir filesep speech_files{ispe} '.wav'];
      speech_signal = speech{ispe};
      start = 1+floor(rand(1).*(size(noise_signal,1)-size(speech_signal,1)-1));
      stop = start+size(speech_signal,1)-1;
      noise_tmp = noise_signal(start:stop,:);
      % Broadcast channels if necessary
      if size(speech_signal,2) > size(noise_tmp,2)
        assert(size(noise_tmp,2) == 1,'cannot broadcast noise channels!');
        noise_tmp = repmat(noise_tmp, 1, size(speech_signal,2));
      elseif size(noise_tmp,2) > size(speech_signal,2)
        assert(size(speech_signal,2) == 1,'cannot broadcast speech channels!');
        speech_signal = repmat(speech_signal, 1, size(noise_tmp,2));
      end
      % Process speech samples with HRIR
      if ~isempty(hrir_speech_idx)
        hrir_speech_tmp = hrir_speech{hrir_speech_idx(isam)};
        if size(speech_signal,2) > size(hrir_speech_tmp,2)
          assert(size(hrir_speech_tmp,2) == 1,'cannot broadcast reverb channels!');
          hrir_speech_tmp = repmat(hrir_speech_tmp, 1, size(speech_signal,2));
        elseif size(hrir_speech_tmp,2) > size(speech_signal,2)
          assert(size(speech_signal,2) == 1,'cannot broadcast speech channels!');
          speech_signal = repmat(speech_signal, 1, size(hrir_speech_tmp,2));
        end
        for ich=1:size(speech_signal,2)
          speech_signal_tmp = fftconv2(speech_signal(:,ich), hrir_speech_tmp(:,ich), 'full');
          speech_signal(:,ich) = real(speech_signal_tmp(1:size(speech_signal,1)));
        end
      end
      % Process noise samples
      if ~isempty(hrir_noise_idx)
        hrir_noise_tmp = hrir_noise{hrir_noise_idx(isam)};
        if size(noise_tmp,2) > size(hrir_noise_tmp,2)
          assert(size(hrir_noise_tmp,2) == 1,'cannot broadcast reverb channels!');
          hrir_noise_tmp = repmat(hrir_noise_tmp, 1, size(noise_tmp,2));
        elseif size(hrir_noise_tmp,2) > size(noise_tmp,2)
          assert(size(noise_tmp,2) == 1,'cannot broadcast speech channels!');
          noise_tmp = repmat(noise_tmp, 1, size(hrir_noise_tmp,2));
        end
        for ich=1:size(noise_tmp,2)
          noise_tmp2 = fftconv2(noise_tmp(:,ich), hrir_noise_tmp(:,ich), 'full');
          noise_tmp(:,ich) = real(noise_tmp2(1:size(noise_tmp,1)));
        end
      end
      % Apply gain and mix signals
      signal = speech_signal .* 10.^(snr./20) + noise_tmp;
      assert(checkchannels(size(signal,2)),'different number of channels!');
      audiowrite(filename, signal, fs, 'BitsPerSample', 32);
      count = count+1;
      fprintf(asciifill(1+floor(count./total.*(length(asciifill)-1))));
    end
  end
end
fprintf('#\n');
fprintf('signals have %i channels\n',checkchannels);
end

function signal = crossfade_extend(signal, crossfade, len)
while (size(signal,1) < len)
  fade = repmat(linspace(0,1,crossfade).',1,size(signal,2));
  signal = [ ...
    signal(1:end-crossfade,:); ...
    signal(1:crossfade,:).* sqrt(fade) + ...
    signal(end-crossfade+1:end,:) .* sqrt(1-fade); ...
    signal(crossfade:end,:) ...
    ];
end
end

function out = checkfs(in)
persistent fs;
if nargin < 1
  out = fs;
else
  if isempty(fs)
    fs = in;
  end
  out = fs == in;
end
end

function out = checkchannels(in)
persistent channels;
if nargin < 1
  out = channels;
else
  if isempty(channels)
    channels = in;
  end
  out = channels == in;
end
end
