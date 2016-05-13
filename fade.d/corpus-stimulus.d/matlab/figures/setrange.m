function out = setrange(in, factor)
in = in(:);
maxval = max(in);
minval = min(in);
ext = factor*(maxval-minval);
out = [minval maxval] + [-0.5 0.5].*ext;
end
