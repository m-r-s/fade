function data = read_text(filename)
% An ugly hack to read text tables with an unknown number of columns

[junk message] = system(['wc -l "' filename '"']);
message = regexp(message,' ','split');
num_rows = str2num(message{1});

if ~(num_rows > 0)
  error('cant determine file length');
end

data = cell(num_rows,1);

fid = fopen(filename,'rt');

for iro = 1:num_rows
  data{iro} = fgetl(fid);
end

fclose(fid);
