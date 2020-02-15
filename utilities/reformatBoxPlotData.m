function [boxValues, boxLabels] = reformatBoxPlotData(boxValues, comboNames)
%% Reformat the data suitable for displaying as a boxplot of correlations
%
%  Parameters:
%     boxValues    (input) n x m array with correlations
%                  and third column is method 2
%     comboNames   m X 1 cell array of combo names
%     boxValues    (output) n*m x 1 array with correlations
%     boxLabels    (output) n*m x 1 cell array with labels

%% Compute the labels and values for the box plot

[n, m] = size(boxValues);
boxNumbers = repmat(1:m, n, 1);
boxNumbers = boxNumbers(:);
boxLabels = comboNames(boxNumbers);
boxValues = boxValues(:);
