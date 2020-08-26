function [dead freqs] = standarddeadregion(id)
% audiograms of my subjects in experiment

% frequencies
freqs = [ 125   250   500  1000  2000  4000  8000];

% dead regions
dead = [...    
            1     1     0     0     0     0     0; ... %
            0     1     1     0     0     0     0; ... %
            0     0     1     1     0     0     0; ... %
            0     0     0     1     1     0     0; ... %
            0     0     0     0     1     1     0; ... %
            0     0     0     0     0     1     1; ... %
            1     1     1     0     0     0     0; ... %
            0     0     1     1     1     0     0; ... %
            0     0     0     0     1     1     1; ... %
            1     1     1     1     0     0     0; ... %
            0     0     0     1     1     1     1; ... %
    ];

dead = dead(id,:);
end


