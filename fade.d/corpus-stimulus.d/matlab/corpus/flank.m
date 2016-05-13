function out = flank(in, rise, fall)
% usage: out = flank(in, rise, fall)
%
% in      - signal
% raise   - raise samples
% fall    - fall samples

out = in;  
out(1:rise) = in(1:rise) .* flank_samples(0,pi,rise);
out(1+end-fall:end) = in(1+end-fall:end) .* flank_samples(pi,0,fall);
end

function out = flank_samples(start,stop,samples)
out = 0.5 .* (1-cos(linspace(start,stop,samples))).';
end
