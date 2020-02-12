function X = huberMean(Y, numberOfStds, iters)
% Perform a Huber mean using the Huber loss function.
% x = huber_mean(Y,rho,iters)
%
% Input:
%   Y : MxN matrix over which to average (columnwise)
%   numberOfStds : Number of robust standard deviation in which the function acts like regular mean (default: 1)
%   iters : number of iterations to perform (default: 1000)
%
% Output:
%   x : 1xN vector that is the roust mean of Y

if ~exist('numberOfStds','var')
    numberOfStds = 1;
end

if ~exist('iters','var')
    iters = 1000;
end

dimensionRobustStd = median(abs(bsxfun(@minus,Y,median(Y,1))),1)*1.4826;

% first normalize (divide) each dimension by its robust standard deviation, then perform the mean, then
% multiply by the robust standard deviation (to denormalize).
X = bsxfun(@times, robustMean(bsxfun(@times, Y,  1 ./ dimensionRobustStd), numberOfStds, iters), dimensionRobustStd);

