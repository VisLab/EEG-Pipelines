function [robustStds, medianValues]= stdFromMad(x, dim)
% [robustStds, medianValues]= std_from_mad(x, dim)
% calculate robust standard deviation using median absolute deviation (MAD)
% acts similar to std and medidan with x being a vector or matrix and 
% dim the dimension to act upon. If no vbalue is provided, it acts on the 
% first dimension: dim == 1

if nargin < 2
    dim = 1;
end

medianValues = median(x, dim);

robustStds = median(abs(bsxfun(@minus, x, medianValues)), dim) * 1.4826;