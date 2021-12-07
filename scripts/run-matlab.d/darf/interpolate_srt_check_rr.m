function interpolate_srt_check_rr(test_snrs, rr, target_rr, num_files, snr_estimate)

  guessing_chance = 1/num_files;
  guessing_range  = 1 - guessing_chance;
  upper_bound = 0.75 * guessing_range + guessing_chance;
  lower_bound = 0.25 * guessing_range + guessing_chance;

  % check if the proposed snr is trapped between snr_estimate+[-1 1] dB
  test_snrs(test_snrs==snr_estimate) = [];
  min_diff = min(abs(test_snrs-snr_estimate));
  max_precision = sum(abs((test_snrs-snr_estimate)) == min_diff);

  % check if interpolation is ok
  tmp1 = rr > lower_bound & rr <= target_rr;
  tmp2 = rr < upper_bound & rr >= target_rr;
  if (any(tmp1) + any(tmp2) > 1) || (max_precision > 1)
    fprintf('1\n');
  else
    fprintf('0\n');
  end
end
