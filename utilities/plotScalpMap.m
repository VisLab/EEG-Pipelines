function h1Fig = plotScalpMap(values, chanlocs, theTitle, axisLimits, ...
                             theColorMap, electrodeFlag)
%% Plot the median dispersion


%% Plot the values
figTitle = [theTitle '[' num2str(median(values)) ']'];
h1Fig = figure('Name', figTitle);
topoplot(values, chanlocs, 'electrodes', electrodeFlag, 'colormap', theColorMap, ...
         'hcolor', [0.55, 0.55, 0.55], 'whitebk', 'on');
if ~isempty(axisLimits)
    caxis(axisLimits)
else
    caxis([0 max(values)]);
end
cb = colorbar;
set(cb, 'fontsize', 12);
set(h1Fig, 'Position', [440, 345, 420, 242]);
if ~isempty(theTitle)
   title(figTitle)
end
set(h1Fig, 'renderer', 'painter');