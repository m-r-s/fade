function gen_cases(ttr,target_rate,real_train_snrs)
  train_snrs  = ttr(:,1);
  test_snrs   = ttr(:,2);
  rr          = ttr(:,3);

  unique_test_snrs = unique(test_snrs);
  unique_train_snrs = unique(train_snrs);

  # 1) case_1, check if all rrs are less or equal to target
  case_1 = all(rr <= target_rate); # --> increase test snrs
  # 2) case_2, check if all rrs are greater or equal to target
  case_2 = all(rr >= target_rate); # --> decrease test snrs

  if ~case_1 & ~case_2
    # 3) find lowest test_snr for target_rate, i.e., the srt
    # remove "virtual" train snrs
    unique_train_snrs = unique_train_snrs(ismember(unique_train_snrs,real_train_snrs));
    test_snr_for_interpolation = min(unique_test_snrs):0.1:max(unique_test_snrs);
    for ii = 1:length(unique_train_snrs);
      i_train_snr = unique_train_snrs(ii);
      ids       = (train_snrs==i_train_snr);
      tmp_test  = test_snrs(ids);
      tmp_train = train_snrs(ids);
      tmp_rates = rr(ids);

      rates_interpolated = interp1(tmp_test,tmp_rates,test_snr_for_interpolation);
      # find first jump, first is always lowest snr
      deltas = abs(diff([rates_interpolated rates_interpolated(end)]<target_rate));
      if length(unique(deltas)) > 1
        # only look for srt if there is a jump
        [~, id_srt]     = max(deltas);
        rate_at_srt(ii) = rates_interpolated(id_srt);
        srt(ii)         = test_snr_for_interpolation(id_srt);
      else
        rate_at_srt(ii) = nan;
        srt(ii)         = nan;
      end
    end

    logical_index = (srt == min(srt));
    [~,id_lowest_srt] = max(logical_index); # omits multiple minima
    cRATE  = rate_at_srt(id_lowest_srt);
    cSRT   = srt(id_lowest_srt);
    cTRAIN = unique_train_snrs(id_lowest_srt);
    # 4) case_3 check if srt was found at greatest training snr
    case_3 = max(unique_train_snrs) == cTRAIN; # --> increase train snr
    # 5) case_4 check if srt was found at lowest training snr and not at greatest train snr,
    #    i.e., first increase train snr before decreasing it
    case_4 = (min(unique_train_snrs) == cTRAIN) && ~case_3; # --> decrease train snr
    # 6) case_5 check if less than two test snrs are below srt
    case_5 = sum(unique_test_snrs < cSRT) < 2;  # --> decrease test snrs
    # 7) case_6 check if the simulation should stop
    case_6 = ~case_3 && ~case_4 && ~case_5; # --> stop simulation
  else
    case_3 = false;
    # check if current adaptation performs a "blackwalk", i.e., only
    #   results in guesses. This is caused by too low training SNRs.
    #   Do this based on the ratio of unique test and train_snrs
    #   starting ratio is 2, end ratio is typically inbetween 0.5 and 1.5
    if case_1 & (numel(unique_test_snrs)/numel(unique_train_snrs) > 3.5) # e.g. 7 test snrs, 2 train snrs
      case_3 = true; # --> increase train snr
    end
    case_4 = false;
    case_5 = false;
    case_6 = false;
  end

  str = sprintf('%1.0f,%1.0f,%1.0f,%1.0f,%1.0f,%1.0f',...
                 case_1, case_2, case_3, case_4, case_5, case_6);
  disp(str)
end
