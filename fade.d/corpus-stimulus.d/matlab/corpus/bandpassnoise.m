function noise = bandpassnoise(samples, frequencies)
% usage: bandpassnoise(samples, frequencies)
%
% samples     - number of samples to generate
% frequencies - [lower upper] normalized cut off frequencies [0..1]

noise = randn(samples,1);
noise_fft = fft(noise);

lowerbound = max(1,round(frequencies(1).*samples)-1);
upperbound = min(samples,round(frequencies(2).*samples)+1);

noise_fft(1:lowerbound) = 0;
noise_fft(upperbound:end) = 0;

noise = real(ifft(noise_fft));
noise = noise./sqrt(mean(noise.^2));
end
