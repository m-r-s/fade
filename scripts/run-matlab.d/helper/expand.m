function varargout = expand(dims, varargin)
% generic expansion function

% Copyright (C) 2014-2016 Marc René Schädler

num_argin = length(varargin);
num_argout = nargout();
% analyse dimensionality
max_siz = size(varargin{1});
max_siz_dim = numel(max_siz);
do_expansion = false;
for i=2:num_argin
    tmp_siz = size(varargin{i});
    tmp_siz_dim = numel(tmp_siz);
    if tmp_siz_dim > max_siz_dim
        max_siz = [max_siz ones(1,tmp_siz_dim-max_siz_dim)];
        max_siz_dim = numel(max_siz);
        do_expansion = true;
    elseif tmp_siz_dim < max_siz_dim
        tmp_siz = [tmp_siz ones(1,max_siz_dim-tmp_siz_dim)];
        do_expansion = true;
    end
    if ~do_expansion && any(max_siz ~= tmp_siz)
        do_expansion = true;
    end
    max_siz = max(max_siz,tmp_siz);
end
% expand requested dimensions
if do_expansion == 1
    max_siz(max_siz==0) = [];
    max_siz_len = length(max_siz);
    for i=1:num_argout
        tmp_siz = size(varargin{i});
        factors = max_siz ./ [tmp_siz ones(1,max_siz_len-length(tmp_siz))];
        if ~isempty(dims)
            factors_select = ones(1,length(factors));
            factors_select(dims) = factors(dims);
            factors = factors_select;
        end
        if all(~mod(factors,1))
            if any(factors ~= 1)
                varargout{i} = repmat(varargin{i},factors);
            else
                varargout{i} = varargin{i};
            end
        else
            error(['could not expand. factors are not iteger: ' num2str(factors)]);
        end
    end
else
    varargout = varargin;
end
end
