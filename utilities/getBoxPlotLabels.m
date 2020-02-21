function [values, methods, channels] = ...
                   getBoxPlotLabels(valueArrays, methodNames, channelLabels)
 %% Produce a labeled vector from a cell array of values for boxplots               
 numMethods = length(methodNames);
 values = [];
 methods = {};
 channels = {};
 for m = 1:numMethods
     theseValues = valueArrays{m};
     [numChannels, numItems] = size(theseValues);
      theseChannels = repmat(channelLabels(:), 1, numItems);
      theseMethods = repmat(methodNames(m), numChannels, numItems);
      values = [values(:); theseValues(:)];
      channels = [channels(:); theseChannels(:)];
      methods = [methods(:); theseMethods(:)];
 end
 