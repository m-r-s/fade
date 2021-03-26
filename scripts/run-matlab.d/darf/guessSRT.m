function out = guessSRT(audiogram, noiselevel, speechlevel, loss_freqs)
  % function to estimate an SRT, idea based on [1]
  if nargin < 1 || isempty(audiogram)
    audiogram = 0;
  end
  if nargin < 2 || isempty(noiselevel)
    noiselevel = 65;
  end
  if nargin < 3 || isempty(speechlevel)
    speechlevel = 65;
  end
  if nargin < 4 || isempty(loss_freqs)
    [~, loss_freqs] = standardaudiogram(1);
  end

  if ischar(audiogram)
    audiogram = str2num(audiogram);
    % The gabel estimation.
  end
  if ischar(noiselevel)
    noiselevel = str2num(noiselevel);
  end

  audiogram = min(audiogram,[],1);
  % select lowest losses

 if length(audiogram) > 1
    % Use provided audiogram
    loss_hl = audiogram(:).';
    loss_spl = ff2ed(loss_freqs,hl2spl(loss_freqs, loss_hl));
  elseif length(audiogram) == 1 && audiogram > 0
    % Load standard audiogram
    [loss_hl, loss_freqs] = standardaudiogram(audiogram);
    loss_spl = ff2ed(loss_freqs,hl2spl(loss_freqs, loss_hl));
  else
    % Normal absolute hearing thresholds
    loss_spl = ff2ed(loss_freqs,hl2spl(loss_freqs, zeros(size(loss_freqs))));
  end
  % get hearing loss for low frequencies, which were found to correlate higher with the SRT [unpublished]
  loss_spl = interp1(loss_freqs, loss_spl, [125 250 375 500 750 1000],'extrap','linear');

  HL        = mean(loss_spl); % mean hearing loss for low frequencies
  NL        = noiselevel; % noise level
  SRT_quiet = 12; % fade SRT for NH in quiet simulated with FADE
  SRT_noise = -8; % fade SRT for NH in stationary, unmodulated noise... with restricted training data
  out = max([HL, NL+SRT_noise, SRT_quiet])-NL; % estimated SRT, (...)-NL due to configuration
  fprintf('%+03.0f\n',out - (speechlevel - NL));
end

% SOURCES
% [1] : Wardenga, N., Batsoulis, C., Wagener, K. C., Brand, T., Lenarz, T., & Maier, H. (2015). Do you hear the noise? The German matrix sentence test with a fixed noise level in subjects with normal hearing and hearing impairment. International journal of audiology, 54(sup2), 71-79.

function y = ff2ed(f, x)
% Free field to eardrum transformation values digitized from [1].
% [1] Shaw, E. A. G., & Vaillancourt, M. M. (1985). Transformation of sound‐pressure level from the free field to the eardrum presented in numerical form. The Journal of the Acoustical society of America, 78(3), 1120-1123.
frequencies   = [0.2 0.25 0.3 0.32 0.4 0.5 0.6 0.63 0.7 0.8 0.9 1.0 1.2 1.25 1.4 ...
                 1.6 1.8 2.0 2.3 2.5 2.7 2.9 3.0 3.2 3.5 4.0 4.5 5.0 5.5 6.0 ...
                 6.3 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0];
values = [0.5 1.0 1.3 1.4 1.5 1.8 2.3 2.4 2.8 3.1 3.0 2.6 2.7 3.0 4.1 ...
          6.1 9.0 12.0 15.9 16.8 16.8 15.8 15.4 14.9 14.7 14.3 12.8 10.7 8.9 7.3 ...
          6.4 5.8 4.3 3.1 1.8 0.5 -0.6 -1.7 -1.7 2.5 6.8 8.4 8.5];
y = x+interp1(frequencies,values,f./1000,'linear','extrap');
end

function y = hl2spl(f, x)
% Hearing thresholds digitized from ISO226 Loudness Curves
f_ht   = [20.7332 21.5443 21.9617 22.8209 23.7137 24.6415 25.1189 25.6055 26.1016 27.1227 27.6482 28.1838 28.7298 29.8538 30.4322 31.6228 32.2354 32.8599 33.4965 34.807 35.4813 36.8695 37.5837 38.3119 39.8107 40.582 41.3682 42.9866 43.8194 44.6684 45.5337 47.3151 48.2318 49.1662 51.0897 52.0795 53.0884 54.117 56.2341 57.3236 58.4341 59.5662 63.0957 65.5642 68.1292 69.4491 70.7946 74.9894 76.4422 77.9232 80.9717 85.7696 90.8518 94.4061 96.2351 103.912 107.978 114.376 121.153 128.332 133.352 138.569 141.254 152.522 155.477 161.56 171.133 177.828 188.365 203.392 207.332 215.443 228.209 237.137 246.415 256.055 266.073 276.482 287.298 298.538 322.354 361.687 383.119 390.541 421.697 455.337 482.318 520.795 541.17 584.341 607.202 643.181 655.642 668.344 721.661 779.232 794.328 809.717 874.312 944.061 962.351 1079.78 1122.02 1143.76 1165.91 1258.93 1359.36 1385.69 1412.54 1467.8 1525.22 1584.89 1615.6 1646.9 1744.48 1847.85 1920.14 2033.92 2073.32 2154.43 2282.09 2371.37 2417.32 2610.16 2818.38 2872.98 3043.22 3162.28 3414.55 3548.13 3686.95 3981.07 4058.2 4298.66 4553.37 4731.51 4916.62 5011.87 5207.95 5411.7 5623.41 5843.41 6072.02 6189.66 6309.57 6556.42 6812.92 7079.46 7356.42 7498.94 7943.28 8413.95 9261.19 9809.95 10592.5 11437.6 11659.1 12115.3 12589.3 13081.8 13856.9 14125.4 14678 16000 20000];
spl_ht = [72.6727 71.4715 70.5706 69.3694 68.4685 67.2673 66.0661 65.7658 65.1652 63.964 63.0631 62.7628 61.8619 60.6607 59.4595 58.5586 57.6577 57.3574 56.1562 55.2553 54.0541 52.8529 52.2523 51.952 50.1502 49.5495 48.9489 48.048 46.8468 46.8468 45.9459 44.7447 44.1441 43.8438 42.6426 41.4414 41.4414 40.5405 39.3393 38.7387 38.4384 37.2372 36.036 34.8348 33.6336 33.3333 32.7327 31.5315 30.9309 30.6306 29.4294 28.5285 27.027 26.1261 26.1261 24.3243 23.4234 22.5225 21.3213 20.4204 19.5195 18.9189 18.6186 17.1171 16.8168 16.2162 15.3153 14.7147 13.8138 12.6126 12.3123 12.012 11.1111 10.8108 10.2102 9.90991 9.30931 9.00901 8.40841 8.10811 7.20721 6.30631 5.70571 5.70571 5.10511 4.5045 4.2042 3.9039 3.6036 3.3033 3.003 3.003 2.7027 2.7027 2.4024 2.4024 2.4024 2.1021 2.1021 2.1021 2.1021 2.1021 2.4024 2.4024 2.4024 3.003 3.3033 3.3033 3.3033 3.003 3.003 2.4024 2.1021 2.1021 1.2012 0 -0.900901 -1.8018 -2.4024 -3.003 -3.9039 -4.5045 -4.8048 -5.40541 -6.00601 -6.00601 -6.00601 -6.30631 -6.30631 -6.00601 -6.00601 -5.10511 -4.8048 -3.9039 -2.7027 -1.8018 -0.600601 -0.3003 0.3003 1.2012 2.4024 3.3033 4.2042 4.8048 5.40541 6.30631 7.50751 8.40841 9.60961 9.90991 11.4114 12.3123 13.8138 14.1141 14.7147 14.7147 15.015 14.7147 14.7147 14.4144 13.8138 13.8138 13.5135 12 100];
y = x+interp1(f_ht,spl_ht,f,'linear');
end

function [loss, freqs] = standardaudiogram(id)
% bisgaard audiograms

% frequencies
freqs = [125   250   375   500   750  1000  1500  2000  3000  4000  6000  8000];

% hearing levels
losses = [...
           0     0     0     0     0     0     0     0     0     0     0     0; ... % N0
          10    10    10    10    10    10    10    15    20    30    40    40; ... % N1
          20    20    20    20    22.5  25    30    35    40    45    50    50; ... % N2
          35    35    35    35    35    40    45    50    55    60    65    65; ... % N3
          55    55    55    55    55    55    60    65    70    75    80    80; ... % N4
          65    65    67.5  70    72.5  75    80    80    80    80    80    80; ... % N5
          75    75    77.5  80    82.5  85    90    90    95   100   100   100; ... % N6
          90    90    92.5  95   100   105   105   105   105   105   105   105; ... % N7
          10    10    10    10    10    10    10    15    30    55    70    70; ... % S1
          20    20    20    20    22.5  25    35    55    75    95    95    95; ... % S2
          30    30    30    35    47.5  60    70    75    80    80    85    85; ... % S3
    ];

loss = losses(id+1,:);
end
