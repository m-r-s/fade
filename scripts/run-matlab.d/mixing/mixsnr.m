function mixsnr(speech_dir, noise_dir, target_dir, snrs, num_samples, sil, seed)
% usage: mixsnr(speech_dir, noise_dir, target_dir, snrs, num_samples, sil, seed)
%
% Mix wav files in "speech_dir" with random portions of those in "noise_dir" 
% until "num_samples" recorsings are reached for each SNR in "snr" and padd the
% resulting files with "sil" seconds of silence and save them to target_dir.
% A random "seed" must be provided. The output is structured for use with FADE.
%

% Copyright (C) 2014-2016 Marc René Schädler

if is_octave
  rand('twister', seed);
else
  rng(seed, 'twister');
end

speech_files = dir([speech_dir filesep '*.wav']);
speech_files = {speech_files.name};
[junk idx] = sort(rand(1,numel(speech_files)));
speech_files = speech_files(idx);

noise_files = dir([noise_dir filesep '*.wav']);
noise_files = {noise_files.name};

num_speech_files= length(speech_files);
num_noise_files = length(noise_files);
num_snrs = length(snrs);

noise = cell(size(noise_files));
speech = cell(size(speech_files));
fs0 = [];

count = 0;
total = num_noise_files*num_snrs*num_samples;
fprintf('a total of %i files will be generated.\n',total);
for i=1:num_noise_files
  [signal, fs] = audioread([noise_dir filesep noise_files{i}]);
  if isempty(fs0)
    fs0 = fs;
  else
    assert(fs==fs0,'different sample frequencies. check your data!');
  end
  % extend noise to minimum of 30 second length
  if size(signal,1) > size(signal,2)
    signal = signal.';
  end
  noise{i} = crossfade_extend(signal, round(fs*.25), round(fs*30));
  [~,noise_files{i}] = fileparts(noise_files{i});
  if ~isempty(strfind(noise_files{i},'_'))
    disp(['underscore (_) in ''' noise_files{i} ''' will be replaced with dash (-)']);
    noise_files{i} = strrep(noise_files{i},'_','-');
  end
end

for i=1:num_speech_files
  [signal, fs] = audioread([speech_dir filesep speech_files{i}]);
  assert(fs==fs0,'different sample frequencies. check your data!');
  if size(signal,1) > size(signal,2)
    signal = signal.';
  end
  speech{i} = [zeros(size(signal,1),round(fs*sil(1))),signal,zeros(size(signal,1),round(fs*sil(2)))];
  [~,speech_files{i}] = fileparts(speech_files{i});
end

t0 = 0;
tic;
for inoi=1:num_noise_files
  noise_signal = noise{inoi};
  noise_size = size(noise_signal);
  noise_dir = [target_dir filesep noise_files{inoi}];
  if ~exist(noise_dir,'dir');
    mkdir(noise_dir);
  end
  for isnr=1:num_snrs
    snr = snrs(isnr);
    fprintf([noise_files{inoi} ' (%i/%i) SNR (%i/%i) %i:'],inoi,num_noise_files,isnr,num_snrs,snr);
    snr_dir = [noise_dir filesep sprintf('snr%+03i',snr)];
    if ~exist(snr_dir,'dir');
      mkdir(snr_dir);
    end
    for isam=1:num_samples
      rep = floor((isam-1)/num_speech_files);
      ispe = isam - num_speech_files * rep;
      sample_dir = [snr_dir filesep sprintf('rep%02d',rep)];
      if ~exist(sample_dir,'dir');
        mkdir(sample_dir);
      end
      filename = [sample_dir filesep speech_files{ispe} '.wav'];
      speech_signal = speech{ispe};
      speech_size = size(speech_signal);
      start = 1+floor(rand(1)*(noise_size(2)-speech_size(2)-1));
      stop = start+speech_size(2)-1;
      noise_tmp = noise_signal(:,start:stop);
      if speech_size(1) > noise_size(1)
        assert(noise_size(1) == 1,'cannot broadcast channels. check your data!');
        noise_tmp = repmat(noise_tmp,speech_size(1),1);
      end
      signal = speech_signal .* 10.^(snr/20) + noise_tmp;
      audiowrite(filename, signal.', fs0, 'BitsPerSample', 32);
      count = count + 1;
    end
    fprintf('\n');
    if toc - t0 > 60
      fprintf('%i files have been written so far. Approximately %i minutes remaining.\n',count,ceil(toc/count*(total-count)/60));
      t0 = toc;
    end
  end
end
end


function signal = crossfade_extend(signal, crossfade, len)
while (size(signal,2) < len)
  signal = [ ...
    signal(:,1:end-crossfade), ...
    signal(:,1:crossfade).*repmat(linspace(0,1,crossfade),size(signal,1),1) + ...
    signal(:,end-crossfade+1:end).*repmat(linspace(1,0,crossfade),size(signal,1),1), ...
    signal(:,crossfade:end) ...
    ];
end
end
