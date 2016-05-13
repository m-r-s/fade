function varargout = control_SM(varargin)

maskerlevels = {'45' '85'};
frequencies = {'750' '900' '1000' '1100' '1250' '1500'};
explanation = {maskerlevels, frequencies};

title = 'Spectral masking';
target = 0.794;
dim = 2;
xfactor = 1/1000;
yfactor = 1;
xlabel = 'Signal (center) frequency [kHz]';
ylabel = 'Threshold [dB SPL]';
xlog = true;
xmarks = [];
ymarks = [0];

frequencies_numeric = cellfun(@str2num,frequencies);

% Empirical data taken from [1]
level = hl2spl(frequencies_numeric, [ ...
   4.70 21.00 38.77 19.53  2.87  0.70; ...
  23.93 56.00 73.37 62.13 49.10 41.83; ...
  ]);
deviation = [ ...
  2.70 1.21 6.39 3.91 3.48 4.12; ...
  4.29 1.60 5.34 3.85 4.57 3.85; ...
  ];

varargout = cell(size(varargin));
for i=1:length(varargin)
  switch varargin{i}
    case 'level'
      varargout{i} = level;
    case 'deviation'
      varargout{i} = deviation;
    case 'target'
      varargout{i} = target;
    case 'xlabel'
      varargout{i} = xlabel;
    case 'ylabel'
      varargout{i} = ylabel;
    case 'xfactor'
      varargout{i} = xfactor;
    case 'yfactor'
      varargout{i} = yfactor;
    case 'explanation'
      varargout{i} = explanation;
    case 'dim'
      varargout{i} = dim;
    case 'xlog'
      varargout{i} = xlog;
    case 'title'
      varargout{i} = title;
    case 'xmarks'
      varargout{i} = xmarks;
    case 'ymarks'
      varargout{i} = ymarks;
  end
end

% [1] Jepsen, M. L., Ewert, S. D., and Dau, T. "A computational model of human
% auditory signal processing and perception." The Journal of the Acoustical 
% Society of America, 124(1):422–438, 2008