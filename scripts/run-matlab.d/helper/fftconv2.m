function out = fftconv2(in1, in2, shape)
% 2D convolution in terms of the 2D FFT that substitutes conv2(in1, in2, shape).
size_y = size(in1,1)+size(in2,1)-1;
size_x = size(in1,2)+size(in2,2)-1;
fft_size_x = 2.^ceil(log2(size_x));
fft_size_y = 2.^ceil(log2(size_y));
in1_fft = fft2(in1,fft_size_y,fft_size_x);
in2_fft = fft2(in2,fft_size_y,fft_size_x);
out_fft = in1_fft .* in2_fft;
out_padd = ifft2(out_fft);
out_padd = out_padd(1:size_y,1:size_x);
switch shape
  case 'same'
    y_offset = floor(size(in2,1)/2);
    x_offset = floor(size(in2,2)/2);
    out = out_padd(1+y_offset:size(in1,1)+y_offset,1+x_offset:size(in1,2)+x_offset);
  case 'full'
    out = out_padd;
end
end
