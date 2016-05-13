function [xt xt_std slopet slopet_std] = find_threshold(x, y, yt, y_std)
% usage: [xt xt_std slopet slopet_std] = find_threshold(x, y, yt, y_std)
%
% calculate value at threshold with error propagation

% Copyright (C) 2014-2016 Marc René Schädler

x = x(:);
y = y(:);

assert(numel(x) == numel(y),'x y must have the same length');

xt = nan;
xt_std = nan;
slopet = nan;
slopet_std = nan;
idx = find(y>yt,1,'first');
if idx == 1
  %warning('first value above threshold');
  xt = -Inf;
  xt_std = Inf;
elseif ~isempty(idx)
  x1 = x(idx-1);
  x2 = x(idx);
  y1 = y(idx-1);
  y2 = y(idx);
  % straight forward linear interpolation
  xt = x1 + (x2-x1)/(y2-y1)*(yt-y1);
  if nargout > 1
    y_std = y_std(:);
    if numel(y) ~= numel(y_std)
        error('y and y_std must have the same length');
    end
    dy1 = y_std(idx-1);
    dy2 = y_std(idx);
    % solved the following error propagation equation with maxima 
    % maxima> xt(y1,y2) := x1 + (x2-x1)/(y2-y1)*(yt-y1); abs(diff(xt(y1,y2),y1))*dy1 + abs(diff(xt(y1,y2),y2))*dy2;
    xt_std = dy1*abs((x2-x1)*(yt-y1)/(y2-y1)^2 - (x2-x1)/(y2-y1)) + dy2*abs(x2-x1)*abs(yt-y1)/(y2-y1)^2;
    if nargout > 2
      slopet = (y2-y1)/(x2-x1);
      if nargout > 3
        err1 = -1/(x2-x1) * dy1;
        err2 = 1/(x2-x1) * dy2;
        slopet_std = abs(err1) + abs(err2);
      end
    end
  end
else
  %warning('no value above threshold');
  xt = Inf;
  xt_std = Inf;
end
