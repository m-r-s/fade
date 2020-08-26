function [uncertainty freqs] = standarduncertainty(id)
% audiograms of my subjects in experiment

% frequencies
freqs = [125   250   375   500   750  1000  1500  2000  3000  4000  6000  8000];

% hearing levels
uncertainties = [...
          0     0     0     0     0     0     0     0     0     0     0     0 ; ... % 0 U0
          1     1     1     1     1     1     1     1     1     1     1     1 ; ... % 1 U1
          2     2     2     2     2     2     2     2     2     2     2     2 ; ...
          3     3     3     3     3     3     3     3     3     3     3     3 ; ...
          4     4     4     4     4     4     4     4     4     4     4     4 ; ...
          5     5     5     5     5     5     5     5     5     5     5     5 ; ...
          6     6     6     6     6     6     6     6     6     6     6     6 ; ...
          7     7     7     7     7     7     7     7     7     7     7     7 ; ... % 7 U7
          8     8     8     8     8     8     8     8     8     8     8     8 ; ...
          9     9     9     9     9     9     9     9     9     9     9     9 ; ...
          10    10    10    10    10    10    10    10    10    10    10    10; ...
          11    11    11    11    11    11    11    11    11    11    11    11; ...
          12    12    12    12    12    12    12    12    12    12    12    12; ...
          13    13    13    13    13    13    13    13    13    13    13    13; ...
          14    14    14    14    14    14    14    14    14    14    14    14; ... % 14 U14
    ];

uncertainty = max(uncertainties(id+1,:), 0.1);
end