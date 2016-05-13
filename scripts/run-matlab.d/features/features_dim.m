function features_dim(filename)
if exist(filename,'file')
  disp(['feature_dim:',num2str(size(readhtk(filename),2))]);
else
  disp('feature_dim:0');
end

end
