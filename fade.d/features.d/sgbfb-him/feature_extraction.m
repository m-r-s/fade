function [features] = feature_extraction(signal, fs, resolution, audiogram, deadregion, uncertainty, compression, audiogram_freqs)
%
% Example hearing-impaired SGBFB feature extraction
%

fs0 = 16000;
band_factor = 4;

if size(signal,2) > size(signal,1)
  signal = signal.';
end

if fs0 ~= fs
  signal = resample(signal, fs0, fs);
end

% Set standard parameter values and convert data types
if nargin < 3 || isempty(resolution)
  resolution = 1;
elseif ischar(resolution)
  resolution = str2num(resolution);
end

if nargin < 4 || isempty(audiogram)
  audiogram = 0;
elseif ischar(audiogram)
  audiogram = str2num(audiogram);
end

if nargin < 5 || isempty(deadregion)
  deadregion = 0;
elseif ischar(deadregion)
  deadregion = str2num(deadregion);
end

if nargin < 6 || isempty(uncertainty)
  uncertainty = 0;
elseif ischar(uncertainty)
  uncertainty = str2num(uncertainty).*sqrt(4);
end

if nargin < 7 || isempty(compression)
  compression = 0;
elseif ischar(compression)
  compression = str2num(compression);
end

if nargin >= 8 && ischar(audiogram_freqs)
  audiogram_freqs = str2num(audiogram_freqs);
end

% Signal check
num_sig_channels = size(signal,2);
assert(num_sig_channels == 1,'only 1 signal channel is supported');

% Calculate the standard log Mel-spectrogram
[log_melspec melspec_freqs] = log_mel_spectrogram(signal, fs0, [], [], [64 8000], [], band_factor);

% Simulate widened filters (in amplitude domain)
if resolution > 0
  widening_filter = hann_win(resolution.*2.*band_factor); % Hanning window with FWHM = resolution
  log_melspec = 10.*log10(conv2(10.^(log_melspec./10),widening_filter,'same')./band_factor); 
end

% Determine hearing threshold
if length(audiogram) > 1
  % Use provided audiogram
  loss_hl = audiogram(:).';
  loss_freqs = audiogram_freqs(:).';
  loss_spl = hl2spl(loss_freqs, loss_hl);
  ht = interp1(loss_freqs, loss_spl, melspec_freqs,'extrap');
elseif length(audiogram) == 1 && audiogram > 0
  % Load standard audiogram
  [loss_hl loss_freqs] = standardaudiogram(audiogram);
  loss_spl = hl2spl(loss_freqs, loss_hl);
  
  % Determine the hearing threshold for melspec center frequencies
  ht = interp1(loss_freqs, loss_spl, melspec_freqs,'extrap');
else
  % Normal absolute hearing thresholds
  ht = hl2spl(melspec_freqs, zeros(size(melspec_freqs)));
end

% Determine dead regions
if length(deadregion) > 1
  % Use provided dead regions
  deadregion = deadregion(:).';
  dead_freqs = audiogram_freqs(:).';
  dead_mask = deadregion;
elseif length(deadregion) == 1 && deadregion > 0
  [dead_mask dead_freqs] = standarddeadregion(deadregion);
else
  dead_freqs = [0 fs];
  dead_mask = [0 0];
end

% Increase hearing threshold in dead regions by 130 dB
dr = interp1(dead_freqs, dead_mask, melspec_freqs,'extrap','nearest');
ht = max(ht,(dr-0.5).*2.*130);

% Only consider amplitudes above hearing threshold (and simulate 1dB threshold noise)
log_melspec = max(bsxfun(@minus, log_melspec, ht.'), randn(size(log_melspec)));

% Add convolutive noise (in log domain)
if uncertainty > 0
  log_melspec = log_melspec + randn(size(log_melspec)).*uncertainty;
end

% Change compression from log to power
if compression > 0
  log_melspec = 10.^((log_melspec.*compression)./20);
end

% Calculate features
features = sgbfb(log_melspec,[pi/(2*band_factor),pi/2]);

% Mean and variance normalization
features = mvn(features);
end


function window_function = hann_win(width)
% A hanning window of "width" with the maximum centered on the center sample
x_center = 0.5;
step = 1/width;
right = x_center:step:1;
left = x_center:-step:0;
x_values = [left(end:-1:1) right(2:end)].';
valid_values_mask = (x_values > 0) & (x_values < 1);
window_function = 0.5 * (1 - ( cos(2*pi*x_values(valid_values_mask))));
end
