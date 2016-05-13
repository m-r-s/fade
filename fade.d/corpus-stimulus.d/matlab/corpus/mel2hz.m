function f = mel2hz(m)
% Convert frequency from Mel to Hz
f = 700.*((10.^(m./2595))-1);
end
