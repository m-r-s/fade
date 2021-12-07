function interpolate_srt(train_snrs, test_snrs, rr, target_rr)
  % function to create plane from input train test snr pairs given a rr
  % at least requires one tt-pair to create equal performance plane
  % also gives train_test_snr_guess as second argument to reach target rr
  % using "interp1" to get the snr directly can result in a "stuck" pattern,
  % e.g.: snrs = [-7 -20 -16], rr = [1 0.27 0.16]
  %
  % could maybe replaced by some linear regression for all points

  if all(train_snrs == test_snrs) ~= 1
    error("Not one vs. one recognition! Aborting!")
  end
  fade_snrs = test_snrs;

  % 1) buffer stuff
  step_snr    =  1;
  elem        = (max(fade_snrs)-min(fade_snrs))/step_snr;
  if sign(min(fade_snrs)) ~= sign(max(fade_snrs))
    elem = elem + 1;
  end
  snrs      = linspace(min(fade_snrs),max(fade_snrs),elem);
  srt_guess = int1d(fade_snrs,rr,snrs,target_rr);
  fprintf('%+03.0f\n',srt_guess);
end

function out = int1d(rr_snrs,rr,snrs,target_rr)
  % interpolate rr
  rr_s   = interp1(rr_snrs,rr,snrs);
  rr_sp2 = (target_rr - rr_s).^2;
  % find rrs below rr threshold, increase if neccessary
  id = [];
  rr_threshold = 0.02;
  while isempty(id)
    id  = find(rr_sp2<rr_threshold);
    rr_threshold = rr_threshold + 0.005;
  end
  % find lowest snr belonging to rr
  snr_id = id(find(snrs(id) == min(snrs(id))));
  out = snrs(snr_id(1));
end
