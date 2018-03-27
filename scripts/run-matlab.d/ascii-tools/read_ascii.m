function varargout = read_ascii(filename)
% Part of an ugly hack to read text tables with an unknown number of columns
data = strsplit(fileread(filename),'\n');
data = data(~cellfun(@isempty,data));
data = cellfun(@regexp,data,repmat({' '},size(data)),repmat({'split'},size(data)),'UniformOutput',0);

num_argout = nargout;

select = @(x) x(1:num_argout);
data = cellfun(select,data,'UniformOutput',0);

data = vertcat(data{:});

for iao = 1:num_argout
  varargout{iao} = data(:,iao);
end
