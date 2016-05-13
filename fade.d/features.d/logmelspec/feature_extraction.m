function features = feature_extraction(signal, fs)
%
% Example log Mel-spectrogram feature extraction
%

fs0 = 16000;

if size(signal,2) > size(signal,1)
  signal = signal.';
end

if fs0 ~= fs
  signal = resample(signal, fs0, fs);
end

num_channels = size(signal,2);
features = cell(num_channels,2);

for i=1:num_channels
  features{i} = log_mel_spectrogram(signal(:,i), fs0);
end

features = vertcat(features{:});

end
