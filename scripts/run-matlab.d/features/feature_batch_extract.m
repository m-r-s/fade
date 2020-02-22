function feature_batch_extract(filelist_load, filelist_save, blocks, block, varargin)

% Copyright (C) 2014-2016 Marc René Schädler

if nargin < 3
  blocks = 1;
  block = 1;
end

% if a filelist is a char array it is supposed to be a filelist
if ischar(filelist_load)
  filelist_load = textread(filelist_load,'%s','delimiter','\n');
end

if ischar(filelist_save)
  filelist_save = textread(filelist_save,'%s','delimiter','\n');
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
