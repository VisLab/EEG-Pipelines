function hFig = makeBlinkRatioBoxPlot(valueArrays, methodNames, ...
                            channelLabels, theTitle, theType, dataLimits, f)
%% Plot boxplots of the value arrays
[values, methods] = getBoxPlotLabels(valueArrays, methodNames, channelLabels);
if ~isempty(f)
    values = f(values);
end

hFig = figure('Name', theTitle{1});
hold on
bxs = boxplot(values, methods, 'orientation', 'vertical', ...
    'DataLim', dataLimits, 'GroupOrder', methodNames);
ylabel(theType)
xlabel('Preprocessing method')
title(theTitle, 'Interpreter', 'none');
set(gca, 'YLim', dataLimits, 'YLimMode', 'manual', 'XTickLabelMode', 'manual', ...
    'XTickLabel', methodNames);
box on
hold off
[~, cols] = size(bxs);
colors = [0.8, 0.8, 0.8];
for j1 = 1:cols
    patch(get(bxs(5, j1),'XData'),get(bxs(5, j1),'YData'), ...
        colors, 'FaceAlpha', 0.5);
    set(bxs(6, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    set(bxs(7, j1), 'MarkerEdgeColor', [0.4, 0.4, 0.4], 'LineWidth', 0.5);
end
hold off
