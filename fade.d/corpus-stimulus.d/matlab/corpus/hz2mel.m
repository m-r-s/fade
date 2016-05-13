function m = hz2mel(f)
% Convert frequency from Hz to Mel
m = 2595.*log10(1+f./700);
end
