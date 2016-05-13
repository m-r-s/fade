function varargout = ccellfun(fhandle, varargin)
% comfortable cell function (expands arguments)

% Copyright (C) 2014-2016 Marc René Schädler

num_argin = length(varargin);

% put contents into cells
%[varargin{:}] = recell(varargin{:});
for i=1:num_argin
    if ~iscell(varargin{i})
        varargin{i} = varargin(i);
    end
end

% expand cells if neccesary
if num_argin > 1
    [varargin{:}] = expand([],varargin{:});
end

varargout = cell(nargout,1);
[varargout{:}] = cellfun(fhandle,varargin{:},'UniformOutput',0);
end
