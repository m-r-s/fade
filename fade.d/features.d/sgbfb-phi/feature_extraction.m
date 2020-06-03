function [features, log_melspec] = feature_extraction(signal, fs, audiogram_profile, level_uncertainty, spectral_resolution)
%
% Hearing-impaired SGBFB feature extraction as used with [1], based on [2]
% With hearing loss (audiogram_profile) according to Bisgaard et. al 2010 [3], 
% with a supra-threshold level uncertainty [4], and
% with a reduced spectral resolution implemented as a widening factor of the frequency bands [1]

  fs0 = 16000; % feel free to change it, 

  % Set standard parameter values and convert data types
  if nargin < 3 || isempty(audiogram_profile)
    audiogram_profile = 0;
  elseif ischar(audiogram_profile)
    audiogram_profile = str2num(audiogram_profile);
  end

  if nargin < 4 || isempty(level_uncertainty)
    level_uncertainty = 0;
  elseif ischar(level_uncertainty)
    level_uncertainty = str2num(level_uncertainty);
  end

  if nargin < 5 || isempty(spectral_resolution)
    spectral_resolution = 1;
  elseif ischar(spectral_resolution)
    spectral_resolution = str2num(spectral_resolution);
  end

  % Signal check
  num_sig_channels = size(signal,2);
  assert(num_sig_channels == 1,'only 1 signal channel is supported');

  if size(signal,2) > size(signal,1)
    signal = signal.';
  end

  if fs0 ~= fs
    signal = resample(signal, fs0, fs);
  end

  % Calculate the log Mel-spectrogram with 4 times as many bands (super-sampling)
  [log_melspec melspec_freqs] = log_mel_spectrogram(signal, fs0, [], [], [], [], 4);

  % Reduce spectral resolution (in energy domain), factor 4 due to supersampling
  widening_filter  = hann_win(spectral_resolution.*2.*4)./4; % Hanning window with FWHM = resolution
  log_melspec_padd = [repmat(log_melspec(1,:),100,1); log_melspec; repmat(log_melspec(end,:),100,1)];
  log_melspec_padd = 10.*log10(conv2(10.^(log_melspec_padd./10),widening_filter,'same'));
  log_melspec      = log_melspec_padd(101:end-100,:);

  % Determine hearing threshold absolute hearing thresholds from standardaudiograms [3] converted to dB SPL (hl2spl) at the eardrum (ff2ed).
  if audiogram_profile > 0
    % Load standard audiogram
    [loss_hl loss_freqs] = standardaudiogram(audiogram_profile); % [3]
    loss_spl = ff2ed(loss_freqs,hl2spl(loss_freqs,loss_hl));     % ff2ed [5], hl2spl [6]
    
    % Determine the hearing threshold for melspec center frequencies
    ht = interp1(loss_freqs, loss_spl, melspec_freqs, 'linear', 'extrap');
  else
    % Normal absolute hearing thresholds (zeros) converted to dB SPL (hl2spl) at the eardrum (ff2ed).
    ht = ff2ed(melspec_freqs,hl2spl(melspec_freqs, zeros(size(melspec_freqs)))); % ff2ed [5], hl2spl [6]
  end

  % Only consider amplitudes above hearing threshold (and simulate 1dB threshold noise)
  % threshold noise is required to omit single value rows/columns in the logms which causes the mvn to throw errors (divide by 0)
  log_melspec = max(bsxfun(@minus, log_melspec, ht.'), randn(size(log_melspec)).*sqrt(4)); % sqrt(4) due to supersampling factor of 4

  % Add convolutive noise (in log domain), i.e., the level uncertainty
  if level_uncertainty > 0
    log_melspec = log_melspec + randn(size(log_melspec)).*(level_uncertainty.*sqrt(4)); % sqrt(4) due to supersampling factor of 4
  end
  
  % calculate features, use pi/8 due to the supersampling factor of 4
  features = mvn(sgbfb(log_melspec,[pi/8,pi/2]));
end

function window_function = hann_win(width)
  % A hanning window of "width" with the maximum centered on the center sample
  x_center = 0.5;
  step = 1./width;
  right = x_center:step:1;
  left = x_center:-step:0;
  x_values = [left(end:-1:1) right(2:end)].';
  valid_values_mask = (x_values > 0) & (x_values < 1);
  window_function = 0.5 * (1 - ( cos(2*pi*x_values(valid_values_mask))));
end

% [1] Hülsmeier, D., Warzybok, A., Kollmeier, B., & Schädler, M. R. (2020). Simulations with FADE of the effect of impaired hearing on speech recognition performance cast doubt on the role of spectral resolution. Hearing Research
% [2] Schädler, M. R., Warzybok, A., Ewert, S. D., & Kollmeier, B. (2016). A simulation framework for auditory discrimination experiments: Revealing the importance of across-frequency processing in speech perception. The journal of the acoustical society of America, 139(5), 2708-2722.
% [3] Bisgaard, N., Vlaming, M. S., & Dahlquist, M. (2010). Standard audiograms for the IEC 60118-15 measurement procedure. Trends in amplification, 14(2), 113-120.
% [4] Kollmeier, B., Schädler, M. R., Warzybok, A., Meyer, B. T., & Brand, T. (2016). Sentence recognition prediction for hearing-impaired listeners in stationary and fluctuation noise with FADE: Empowering the attenuation and distortion concept by Plomp with a quantitative processing model. Trends in hearing, 20, 2331216516655795.
% [5] Shaw, E. A. G., & Vaillancourt, M. M. (1985). Transformation of sound‐pressure level from the free field to the eardrum presented in numerical form. The Journal of the Acoustical society of America, 78(3), 1120-1123.
% [6] ISO:226, B. (2003). 226: 2003: Acoustics–normal equal-loudness-level contours. International Organization for Standardization, 02(04):143–149.
