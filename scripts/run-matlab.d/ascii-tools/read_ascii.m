function varargout = read_ascii(filename)
% Part of an ugly hack to read text tables with an unknown number of columns

data = read_text(filename);
data = cellfun(@regexp,data,repmat({' '},size(data)),repmat({'split'},size(data)),'UniformOutput',0);
data = vertcat(data{:});

num_argout = nargout;

for iao = 1:num_argout
  varargout{iao} = data(:,iao);
end
