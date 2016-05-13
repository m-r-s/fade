function pos = subposition(m, n, p, s, o, z)
%  usage: pos = subposition(m, n, p, s, o, z)
%
%  Calculates position vectors for axes('Position',pos)
%  in the style of the subplot command.
%  Spacing s, offset o, and zoom z may be optionally set
%  in the interval [0 1]
%
%  You may replace your subplot command by using:
%    subplot = @(m,n,p) axes('Position',subposition(m,n,p))
%

%  Copyright (C) 2014-2016 Marc René Schädler

if nargin < 4 || isempty(s)
  s = [1 1]*2^-4;
end

if nargin < 5 || isempty(o)
  o = [1 1]*2^-6;
end

if nargin < 6 || isempty(z)
  z = [1 1]*0.95;
end

num_pos = length(p);
x = zeros(1,num_pos);
y = zeros(1,num_pos);
w = zeros(1,num_pos);
h = zeros(1,num_pos);

for i=1:num_pos
  [x(i) y(i) w(i) h(i)] = position(m, n, p(i), s, o, z);
end

pos = [min(x) min(y) max(x)-min(x)+max(w) max(y)-min(y)+max(h)];
end

function [x y w h] = position(m, n, p, s, o, z)
w_f = 1/n;
h_f = 1/m;

w = w_f - s(2);
h = h_f - s(1);

[xi yi] = ind2sub([n m], p);

yi = m - yi + 1;

x = w_f*(xi-1) + s(2)/2 + o(2);
y = h_f*(yi-1) + s(1)/2 + o(1);

w = w*z(2);
h = h*z(1);
x = (x - 0.5)*z(2) + 0.5;
y = (y - 0.5)*z(1) + 0.5;
end
