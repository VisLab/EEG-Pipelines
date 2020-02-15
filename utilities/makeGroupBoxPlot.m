function hFig = makeGroupBoxPlot(correlations, labels, theTitle, groupOrder)

dataLimits = [0, 1];
hFig = figure('Name', theTitle{1});
hold on
bxs = boxplot(correlations, labels, 'orientation', 'horizontal', ...
    'DataLim', dataLimits, 'groupOrder', groupOrder);
ylabel('Type')
xlabel('Correlation')
title(theTitle, 'Interpreter', 'none');
yLimits = get(gca, 'YLim');
line([0, 0], yLimits, 'Color', [0.8, 0.8, 0.8]);
set(gca, 'XLim', dataLimits, 'XLimMode', 'manual');
box on
axis ij
line([0.5, 0.5], yLimits, 'Color', [0.2, 0.2, 0.2]);

[~, cols] = size(bxs);
% colors = lines(5);
% colors(5, :) = [0.4, 0.4, 0.4];
% patchColors = [0.8, 0.8, 0.8; 0.8, 1, 0.8];
for j1 = 1:cols
    patch(get(bxs(5, j1),'XData'),get(bxs(5, j1),'YData'), ...
        [0.8, 0.8, 0.8], 'FaceAlpha', 0.5);
    set(bxs(6, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    set(bxs(7, j1), 'MarkerEdgeColor', [0.4, 0.4, 0.4], 'LineWidth', 0.5);
end
hold off

