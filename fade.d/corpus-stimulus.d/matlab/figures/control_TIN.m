function varargout = control_TIN(varargin)

nul = {''};
duration = {'0.005' '0.015' '0.020' '0.035' '0.050' '0.100' '0.200'};
explanation = {nul, duration};

title = 'Tone-in-noise';
target = 0.707;
dim = 2;
xfactor = 1000;
yfactor = 1;
xlabel = 'Tone duration [ms]';
ylabel = 'Threshold [dB SPL]';
xlog = true;
xmarks = [];
ymarks = [0];

% Data from [1]
level = [68 59 58 55 54 52 50];
deviation = [2.1 1.4 1.4 0.71 0.97 0.90 1.3];

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

% [1] Moore, B. C. J., Alcántara, J. I., and Dau, T. "Masking patterns for
% sinusoidal and narrow-band noise maskers." The Journal of the Acoustical 
% Society of America, 104(2):765 1023–1038, 1998.
