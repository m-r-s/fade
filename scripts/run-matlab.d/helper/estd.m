function y = estd(total, correct, n)
% Estimate std with bootstrapping

% Copyright (C) 2014-2016 Marc René Schädler

persistent cache;

if nargin < 3
  n = 1000;
end

total = round(total);
correct = round(correct);

% Parameter config string
config = sprintf('c%.0f', [total correct n]);
% Only estimate if not cached
if isempty(cache) || ~isfield(cache, config)
  if total == 0
    x = nan;
    y = nan;
  else
    x = [zeros(1,total-correct) ones(1,correct)];
    y = std(mean(x(ceil(rand(total,n)*total))));
  end
  cache.(config) = y;
else
  % Load from cache
  y = cache.(config);
end
end
