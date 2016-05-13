function signal = sinewavephase(samples, frequency, phase)
%usage: signal = sinewavephase(samples, frequency, phase)
%
% samples     - number of samples
% frequency   - normalized frequency [0..1]
% phase       - phase [0..2*pi]

if nargin < 3; phase = 0; end
signal = sin(linspace(0,2.*pi.*frequency.*(samples-1),samples) + phase).';
end
