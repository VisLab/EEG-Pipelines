function h1Fig = plotScalpMap(blockValue, theTitle, axisLimits, ...
                      theColorMap, values, electrodeFlag, figureVisibility)
%% Plot the median dispersion

%% Handle the color limits if needed
if nargin < 3
    axisLimits = [];
end

%% Set the color map
if nargin < 4 || isempty(theColorMap)
   theColorMap = parula(20);
end

if nargin < 5 || isempty(values)
    values = blockValue.tensor;
end

if nargin < 6 || isempty(electrodeFlag)
    electrodeFlag = 'labels';
end

if nargin < 7 || isempty(figureVisibility)
    figureVisibility = 'on';
end
%% Plot the dispersion
c = blockValue.channel;
figTitle = [theTitle '[' num2str(median(values)) ']'];
h1Fig = figure('Name', figTitle, 'Visible', figureVisibility);
c.topoplot(values, 'electrodes', electrodeFlag, 'colormap', theColorMap, ...
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