function [Vt minidx] = lowest_psy(x, y, Z, E, t)
% usage: [Vt minidx] = lowest_psy(x, y, Z, E, t)
%
% find the lowest levels at threshold with 2sigma security margin
% 

% Copyright (C) 2014-2016 Marc René Schädler

% allocate space for derived values at thresholds:
% 1: x at threshold
% 2: x deviation at threshold
% 3: slope at threshold
% 4: slope deviation at threshold
Vt = inf(length(y),4);

% find the values at the thresholds
for i=1:length(y)
  [xt_tmp xtd_tmp st_tmp std_tmp] = find_threshold(x, Z(i,:), t, E(i,:));
  Vt(i,1:4) = [xt_tmp xtd_tmp st_tmp std_tmp];
end

% get the lowest value at threshold of a sane function
[junk, minidx] = min(Vt(:,1)+2.*Vt(:,2));
end
