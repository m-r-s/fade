function feature_batch_extract(filelist_load, filelist_save, blocks, block, varargin)

% Copyright (C) 2014-2016 Marc René Schädler

if nargin < 3
  blocks = 1;
  block = 1;
end

% if a filelist is a char array it is supposed to be a filelist
if ischar(filelist_load)
  fid_load = fopen(filelist_load);
  tmp_load = textscan(fid_load,'%s','delimiter','\n');
  filelist_load = tmp_load{1};
  fclose(fid_load);
end

if ischar(filelist_save)
  fid_save = fopen(filelist_save);
  tmp_save = textscan(fid_save,'%s','delimiter','\n');
  filelist_save = tmp_save{1};
  fclose(fid_save);
end

if length(filelist_load) == length(filelist_save)
  num_files = length(filelist_load);
end

frameperiod = 1/100; %seconds

for i=block:blocks:num_files
  [signal fs] = audioread(filelist_load{i});
  features = feature_extraction(signal, fs, varargin{:});
  writehtk(filelist_save{i}, features.', frameperiod, 9);
  fprintf('.');
end
end
