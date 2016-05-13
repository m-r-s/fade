function features = feature_extraction(signal, fs)
%
% Example PEMO feature extraction
%

persistent amtloaded

if isempty(amtloaded) || ~amtloaded
  if is_octave
    pkg load ltfat;
  end
  amtstart;
  amtloaded = true;
end

fs0 = 16000;
N = round(0.025*fs0);
M = round(0.010*fs0);

if size(signal,2) > size(signal,1)
  signal = signal.';
end

if fs0 ~= fs
  signal = resample(signal, fs0, fs);
end

num_channels = size(signal,2);
features = cell(num_channels,2);

calibration_gain = 10.^(30./20);

for i=1:num_channels
  features_tmp = dau1997preproc(signal(:,i).*calibration_gain, fs0);
  features_tmp = horzcat(features_tmp{:});
  features_tmp = upfirdn(features_tmp, hanning(N), 1, M);
  features_tmp = features_tmp(6:end,:).';
  features{i} = features_tmp;
end

features = vertcat(features{:});
end


function r = is_octave ()
  persistent x;
  if (isempty (x))
    x = exist ('OCTAVE_VERSION', 'builtin');
  end
  r = x;
end

