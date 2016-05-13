function h = plotdev(x,y,e,c)
x=x(:).';
y=y(:).';
e=e(:).';

if nargin < 4 || isempty(c)
  c = [1 .75 .75];
end

valid_mask = ~isnan(x) & ~isinf(x) & ~isinf(y) & ~isnan(y);
x = x(valid_mask);
y = y(valid_mask);
e = e(valid_mask);

xval = [x fliplr(x)];
yval = [y+e fliplr(y-e)];

if (is_octave)
  c = c.';
end

h = fill(xval,yval,c);
set(h,'EdgeColor',c);
end
