function features = feature_extraction(signal, fs, listener, uncertainty)
% usage: features = feature_extraction(signal, fs, listener, uncertainty)
%   signal        waveform signal
%   fs            sample rate in Hz
%   listener      valid id of profile in "load_audiogram.m"
%   uncertainty   level uncertainty
%
% - Feature extraction to take binaural hearing thresholds into account -
%
%
% Copyright (C) 2018-2019 Marc René Schädler
% E-mail marc.r.schaedler@uni-oldenburg.de
% Institute Carl-von-Ossietzky University Oldenburg, Germany
%
%-----------------------------------------------------------------------------
%
% Release Notes:
% v1.0 - Inital release
% v2.0 - Add uncertainty variable (default 1.0, before 0.1)

if nargin < 3 || isempty(listener)
  listener = 0;
end

if nargin < 4 || isempty(uncertainty)
  uncertainty = 1;
end

if ischar(listener)
  listener = str2num(listener);
end

if ischar(uncertainty)
  uncertainty = str2num(uncertainty);
end

persistent config;

% Config id string
configid = sprintf('c%.0f', fs, listener);

if isempty(config) || ~isfield(config, configid)
  % Set up hearing impairment
  [loss_hl_left, loss_freqs_left] = load_audiogram(listener, 'left');
  [loss_hl_right, loss_freqs_right] = load_audiogram(listener, 'right');
  loss_spl_left = ff2ed(loss_freqs_left,hl2spl(loss_freqs_left, loss_hl_left)); % Level at eardrum
  loss_spl_right = ff2ed(loss_freqs_left,hl2spl(loss_freqs_right, loss_hl_right)); % Level at eardrum
  loss_spl = [loss_spl_left; loss_spl_right];
  loss_freqs = [loss_freqs_left; loss_freqs_right];
  config.(configid).loss_spl = loss_spl;
  config.(configid).loss_freqs = loss_freqs;
else
  loss_spl = config.(configid).loss_spl;
  loss_freqs = config.(configid).loss_freqs;
end

% Skip the first 100ms of the signal
signal = single(signal(1+round(fs.*0.100):end,:));

if size(signal,2) == 1
  signal = [signal, signal];
end

% SGBFB ABEL feature extraction
% Separate left and right channel
signal_left = signal(:,1);
signal_right = signal(:,2);
% Calculate log Mel-spectrograms with spectral super-sampling (factor 2)
[log_melspec_left melspec_freqs_left] = log_mel_spectrogram(signal_left, fs, [], [], [], [], 2);
[log_melspec_right melspec_freqs_right] = log_mel_spectrogram(signal_right, fs, [], [], [], [], 2);
% Get left and right hearing thresholds
ht_left = interp1(loss_freqs(1,:), loss_spl(1,:), melspec_freqs_left, 'linear', 'extrap');
ht_right = interp1(loss_freqs(2,:), loss_spl(2,:), melspec_freqs_right, 'linear', 'extrap');
% Only represent signal portions above the threshold
log_melspec_left = max(bsxfun(@minus, log_melspec_left, ht_left.'), 0);
log_melspec_right = max(bsxfun(@minus, log_melspec_right, ht_right.'), 0);
% Add a small amount of level uncertainty (0.1) to avoid "all-zero" channels
log_melspec_left = log_melspec_left + randn(size(log_melspec_left)).*uncertainty;
log_melspec_right = log_melspec_right + randn(size(log_melspec_right)).*uncertainty;
% Extract SGBFB features (with adapted parameters to compensate the spectral super-sampling)
features_left = sgbfb(single(log_melspec_left), [pi/4 pi/2]);
features_right = sgbfb(single(log_melspec_right), [pi/4 pi/2]);
% Concatenate left and right feature vectors and perform mean and variance normalization
features = mvn([features_left; features_right]);
end

