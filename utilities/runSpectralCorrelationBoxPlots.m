%% Performs a boxplot of spectral summary
saveFolder = 'D:\Papers\Current\LARGIIDataCatalogInfo\spectralRelationships';
suffix = '_spectralCorrelationsAcrossMethods.mat';
imageFolder = 'D:\Papers\Current\LARGIIFigures\spectraRelationships';
figureVisibility = 'on';
figureClose = false;
figureFormats = {'.png', 'png'; '.fig', 'fig'; '.pdf' 'pdf'; '.eps', 'epsc'};
%%
if ~exist(imageFolder, 'dir')
    mkdir(imageFolder);
end

%% Study info: dir inst site, shortName, studyTitle
removedStudies = {'RSVP', 'RWN_VDE', 'FLERP', 'VEP'};
[studies, meanings] = getStudies(removedStudies, false);
numStudies = size(studies, 1);
studyRootPos = find(strcmpi(meanings, 'studyRoot'), 1, 'first');
studyNamePos = find(strcmpi(meanings, 'studyName'), 1, 'first');
shortNamePos = find(strcmpi(meanings, 'shortName'), 1, 'first');
comboLabels = {'Larg vs Mara', 'Larg vs Asr_10', 'Larg vs Asr_5', ...
               'Mara vs Asr_10', 'Mara vs Asr_5', 'Asr_10 vs Asr_5'};
studyPlotOrder = {'Cue', 'GuardA', 'GuardB', 'LKBase', 'LKCal',...
                  'LKSp', 'LKTraf', 'Mind', 'RsvpB', 'RsvpC', ...
                  'RsvpE', 'RsvpI', 'Das', 'DD', ...
                  'LKwAF', 'ACC', 'RsvpUA'};
bandOrder = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
% template = struct('uuid', NaN, 'site', NaN, 'study', NaN, 'labId', NaN, ...
%     'srate', NaN, 'frequencies', NaN, 'scales', NaN, ...
%     'correlations', NaN, 'bandCorrelations', NaN);
% 
% save([saveFolder filesep studyName '_spectrogramCorrelationsAcrossMethods.mat'], ...
%         'spectrogramRecs', 'studies', 'typeNames', 'commonChannels', ...
%         'freqs', 'scales', 'freqBands', 'freqBandNames', ...
%         'freqBandNames'); 
 
%% Set up the channels and covariance template
commonChannels = getCommonLabels();
numChans = length(commonChannels);
studyCorrs = [];
studyLabels = {};
studyBandCorrs = [];
typeLabels = {};
bandTypeLabels = {};
bandLabels = {};
bandStudyLabels = {};
for n = 1:numStudies
    %% Setup up the folders and see if the results have already been calculated
    studyName = studies{n, studyNamePos};
    shortName = studies{n, shortNamePos};
    fprintf('\nStarting %s\n', studyName);
    temp = load([saveFolder filesep studyName suffix]);
    sRecs = temp.spectralRecs;
    
    typeNames = temp.typeNames;
    freqBandNames = temp.freqBandNames;
    freqBandNames = freqBandNames(:)';
    numBands = length(freqBandNames);
    numTypes = length(typeNames);
    numCombos = numTypes*(numTypes - 1)/2;
    
    %% Now make sure that all the values are there
    uuids = {sRecs.uuid};
    uuidMask = false(length(uuids), 1);
    for m = 1:length(uuids)
        if isnan(uuids{m})
            uuidMask(m) = true;
        end
    end
    sRecs(uuidMask) = [];
    numRecs = length(sRecs);
    [numChans, numSamples] = size(sRecs(1).randomNums);
    sCorrs = [];
    sBandCorrs = [];
    tLabels = {};
    bLabels = {};
    bTypeLabels = {};
    comboNames = cell(numCombos, 1);
    c = 0;
    for m1 = 1:numTypes - 1
        for m2 = m1+1:numTypes
            tName = [typeNames{m1} '_' typeNames{m2}];
            c = c + 1;
            comboNames{c} = tName;
            for k = 1:numRecs
                theseCorrs = sRecs(k).correlations(:, :, m1, m2);
         
                theseCorrs = theseCorrs(:);
                sCorrs = [sCorrs; theseCorrs]; %#ok<*AGROW>
                tLabels = [tLabels; repmat({tName}, length(theseCorrs), 1)];
                theseBandCorrs = sRecs(k).bandCorrelations(:, :, m1, m2);
                theseBandCorrs = theseBandCorrs(:);
                theseBTypeLabels = repmat({tName}, length(theseBandCorrs), 1);
                theseBLabels = repmat(freqBandNames, numChans, 1);
                theseBLabels = theseBLabels(:);
                sBandCorrs = [sBandCorrs; theseBandCorrs];
                bLabels = [bLabels; theseBLabels];
                bTypeLabels = [bTypeLabels; theseBTypeLabels];
            end
        end
    end
    studyLabels = [studyLabels; repmat({shortName}, length(sCorrs), 1)];
    studyCorrs = [studyCorrs; sCorrs];
    studyBandCorrs = [studyBandCorrs; sBandCorrs];
    typeLabels = [typeLabels; tLabels];
    bandLabels = [bandLabels; bLabels];
    bandTypeLabels = [bandTypeLabels; bTypeLabels];
     bandStudyLabels = [bandStudyLabels; repmat({shortName}, length(sBandCorrs), 1)]; 
end

%% Boxplot of different type combinations
dataLimits = [0, 1];
theTitle = 'Correlation of spectral vectors for preprocessing methods';
h1Fig = figure('Name', theTitle, 'Visible', figureVisibility);
hold on
bxs = boxplot(studyCorrs, typeLabels, 'orientation', 'horizontal', ...
    'DataLim', dataLimits, 'GroupOrder', comboNames);
ylabel('Type')
xlabel('Correlation')
title(theTitle, 'Interpreter', 'none');
set(gca, 'XLim', dataLimits, 'XLimMode', 'manual', 'YTickLabelMode', 'manual', ...
    'YTickLabel', comboLabels);
yLimits = get(gca, 'YLim');
line([0.5, 0.5], yLimits, 'Color', [0.2, 0.2, 0.2]);
box on
axis ij
[~, cols] = size(bxs);
colors = [0.8, 0.8, 0.8];
for j1 = 1:cols
    set(bxs(5, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    patch(get(bxs(5, j1),'XData'),get(bxs(5, j1),'YData'), ...
        colors, 'FaceAlpha', 0.5);
    set(bxs(6, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    set(bxs(7, j1), 'MarkerEdgeColor', [0.4, 0.4, 0.4], 'LineWidth', 0.5);
end
hold off
baseFile = [imageFolder filesep 'spectralCorrelationByType'];
saveFigures(h1Fig, baseFile, figureFormats, figureClose);

%% Plot the different combinations
for c = 1:length(comboLabels)
    figureVisibility = 'on';
    dataLimits = [0, 1];
    theTitle = ['Correlation by band of ' comboLabels{c}];
    h2Fig = figure('Name', theTitle, 'Visible', figureVisibility);
    hold on
    labelMask = strcmpi(bandTypeLabels, comboNames{c});
    bxs = boxplot(studyBandCorrs(labelMask), bandLabels(labelMask), ...
        'orientation', 'horizontal', ...
        'DataLim', dataLimits, 'GroupOrder', bandOrder);
    ylabel('Type')
    xlabel('Correlation')
    title(theTitle, 'Interpreter', 'none');
    yLimits = get(gca, 'YLim');
    line([0.5, 0.5], yLimits, 'Color', [0.2, 0.2, 0.2]);
    set(gca, 'XLim', dataLimits, 'XLimMode', 'manual', 'YTickLabelMode', 'manual', ...
        'YTickLabel', bandOrder);
    box on
    axis ij
    [~, cols] = size(bxs);
    colors = lines(5);
    for j1 = 1:cols
        jP = mod(j1, 5) + 1;
        patch(get(bxs(5, j1),'XData'),get(bxs(5, j1),'YData'), ...
            colors(6-jP, :), 'FaceAlpha', 0.5);
        set(bxs(6, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
        set(bxs(7, j1), 'MarkerEdgeColor', [0.4, 0.4, 0.4], 'LineWidth', 0.5);
    end
    hold off
    baseFile = [imageFolder filesep 'spectralCorrelation_ ' comboNames{c}];
    saveFigures(h2Fig, baseFile, figureFormats, figureClose);
end
%% %% Plot the different combinations
[newLabels, newOrder, newYTickLabels] = makeCombinedLabels(bandTypeLabels, ...
              bandLabels, comboNames, bandOrder, comboLabels);


dataLimits = [0, 1];
theTitle = 'Correlation by band of spectral vectors for preprocessing methods';
h3Fig = figure('Name', theTitle, 'Visible', figureVisibility);
hold on
bxs = boxplot(studyBandCorrs, newLabels, 'orientation', 'horizontal', ...
    'DataLim', dataLimits, 'groupOrder', newOrder);
ylabel('Type')
xlabel('Correlation')
title(theTitle, 'Interpreter', 'none');
yLimits = get(gca, 'YLim');
yTicks = get(gca, 'YTick');
set(gca, 'XLim', dataLimits, 'XLimMode', 'manual', 'YTickLabelMode', 'manual', ...
    'YTickLabel', newYTickLabels);
box on
axis ij
line([0.5, 0.5], yLimits, 'Color', [0.2, 0.2, 0.2]);
base = 5.5;
for j1 = 1:6
    line([0, 1], [base, base], 'LineStyle', '-', 'Color', [0.2, 0.2, 0.2]);
    base = base + 5;
end

[~, cols] = size(bxs);
colors = lines(5);
%colors = [0.4, 0.4, 0.4; colors];
patchColors = [0.8, 0.8, 0.8; 0.8, 1, 0.8];
for j1 = 1:cols
    jP = mod(j1, 5) + 1;
    %set(bxs(5, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    patch(get(bxs(5, j1),'XData'),get(bxs(5, j1),'YData'), ...
        colors(6-jP, :), 'FaceAlpha', 0.5);
    set(bxs(6, j1), 'Color', [0, 0, 0], 'LineWidth', 1);
    set(bxs(7, j1), 'MarkerEdgeColor', [0.4, 0.4, 0.4], 'LineWidth', 0.5);
end
hold off
baseFile = [imageFolder filesep 'spectralBandCorrelationSummary'];
saveFigures(h3Fig, baseFile, figureFormats, figureClose);

