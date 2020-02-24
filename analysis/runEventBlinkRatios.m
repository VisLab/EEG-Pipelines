%% Calculate blink event ratios for a dataset for different preprocessing methods

%% Set up the data
dataDir = 'D:\Research\EEGPipelineProject\dataOut';
imageDir = 'D:\Research\EEGPipelineProject\dataImages';
eegBaseFile = 'basicGuardSession3Subj3202Rec1';
%eegBaseFile = 'dasSession16Subj131004Rec1';
%eegBaseFile = 'speedControlSession1Subj2015Rec1';
%eegBaseFile = 'trafficComplexitySession1Subj2002Rec1';
methodNames = {'LARG', 'MARA', 'ASR_10', 'ASRalt_10', 'ASR_5', 'ASRalt_5'};
numMethods = length(methodNames);
useLogSpectra = false;
inRange = [-1, 1];
outRange = [-2, -1; 1, 2];

%% Specify the formats in which to save the data
%figureFormats = {'.png', 'png'; '.fig', 'fig'; '.pdf' 'pdf'; '.eps', 'epsc'};
figureFormats = {'.png', 'png'};
figureClose = false;

%% Make sure that image directory exists
if ~isempty(imageDir) && ~exist(imageDir, 'dir')
    mkdir(imageDir);
end

%% Read in the files
eegs = cell(numMethods, 1);
for m = 1:numMethods
    fileName = [dataDir filesep eegBaseFile '_' methodNames{m} '.set'];
    eegs{m} = pop_loadset(fileName);
end
channelLabels = getCommonChannelLabels();
numChans = length(channelLabels);

%% Calculate the event blink and non-blink ratios
blinkPowerRatios = cell(numMethods, 1);
nonBlinkPowerRatios = cell(numMethods, 1);
blinkAmpRatios = cell(numMethods, 1);
nonBlinkAmpRatios = cell(numMethods, 1);
erpBlinkPowerRatio = cell(numMethods, 1);
nonBlinkErpPowerRatio = cell(numMethods, 1);
erpBlinkAmpRatio = cell(numMethods, 1);
nonBlinkErpAmpRatio = cell(numMethods, 1);
for m = 1:numMethods
    [EEG, missing, selectMask] = selectEEGChannels(eegs{m}, channelLabels);
    if ~isempty(missing)
        warning('EEG is missing channels %s\n-- can not compute spectral fingerprints', ...
            getListString(missing, ','));
        continue;
    end
    
    %% Now calculate the ratios
   [blinkPowerRatios{m}, nonBlinkPowerRatios{m}, blinkAmpRatios{m},  ...
           nonBlinkAmpRatios{m}, numBlinks, numOverlaps,... 
           erpBlinkPowerRatio{m}, nonBlinkErpPowerRatio{m}, ...
           erpBlinkAmpRatio{m}, nonBlinkErpAmpRatio{m}] = ...
                               getEEGBlinkRatios(EEG, inRange, outRange);     
end

%% Plot box plots of individual blink power ratios
dataLimits = [0, 5];
theTitle = {'Blink power ratio for preprocessing methods'; eegBaseFile};
theType = 'Power ratio';
f = [];
hFig1 = makeBlinkRatioBoxPlot(blinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'blinkPowerRatios_' eegBaseFile];
    saveFigures(hFig1, baseFile, figureFormats, figureClose);
end

%% Plot box plots of individual non-blink power ratios
dataLimits = [0, 5];
theTitle = {'Non blink power ratio for preprocessing methods'; eegBaseFile};
theType = 'Power ratio';
hFig2 = makeBlinkRatioBoxPlot(nonBlinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'nonBlinkPowerRatios_' eegBaseFile];
    saveFigures(hFig2, baseFile, figureFormats, figureClose);
end

%% Plot box plots on blink amplitude ratios
dataLimits = [0, 5];
theTitle = {'Blink amplitude ratio for preprocessing methods'; eegBaseFile};
theType = 'Amplitude ratio';
f = [];
hFig3 = makeBlinkRatioBoxPlot(blinkAmpRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'blinkAmplitudeRatios_' eegBaseFile];
    saveFigures(hFig3, baseFile, figureFormats, figureClose);
end

%% Plot box plots of non-blink amplitude ratios
dataLimits = [0, 5];
theTitle = {'Non blink amplitude ratio for preprocessing methods'; eegBaseFile};
theType = 'Amplitude ratio';
hFig4 = makeBlinkRatioBoxPlot(nonBlinkAmpRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'nonBlinkAmplitudeRatios_' eegBaseFile];
    saveFigures(hFig4, baseFile, figureFormats, figureClose);
end

%% Plot box plots of sqrt blink power ratio 
dataLimits = [0, 5];
theTitle = {'Blink power ratio for preprocessing methods'; eegBaseFile};
theType = 'Sqrt power ratio';
f = @sqrt;
hFig5 = makeBlinkRatioBoxPlot(blinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'blinkSqrtPowerRatios_' eegBaseFile];
    saveFigures(hFig5, baseFile, figureFormats, figureClose);
end        
     
%% Plot box plots of sqrt non blink power ratio 
dataLimits = [0, 5];
theTitle = {'Non blink power ratio for preprocessing methods'; eegBaseFile};
theType = 'Sqrt power ratio';
hFig6 = makeBlinkRatioBoxPlot(nonBlinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'nonBlinkSqrtPowerRatios_' eegBaseFile];
    saveFigures(hFig6, baseFile, figureFormats, figureClose);
end  

%% Now plot boxplots of ERP blink power ratios
dataLimits = [0, 20];
theTitle = {'Blink ERP power ratio for preprocessing methods'; eegBaseFile};
theType = 'ERP power ratio';
f = [];
hFig7 = makeBlinkRatioBoxPlot(erpBlinkPowerRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'blinkERPPowerRatios_' eegBaseFile];
    saveFigures(hFig7, baseFile, figureFormats, figureClose);
end          
  
%% Plot box plots of non-blink ERP power ratios
dataLimits = [0, 20];
theTitle = {'Non blink ERP power ratio for preprocessing methods'; eegBaseFile};
theType = 'ERP power ratio';
hFig8 = makeBlinkRatioBoxPlot(nonBlinkErpPowerRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'nonBlinkERPPowerRatios_' eegBaseFile];
    saveFigures(hFig8, baseFile, figureFormats, figureClose);
end   

%% Plot box plots of blink ERP amplitude ratios
dataLimits = [0, 5];
theTitle = {'Blink ERP amplitude ratio for preprocessing methods'; eegBaseFile};
theType = 'Amplitude ratio';
f = [];
hFig9 = makeBlinkRatioBoxPlot(erpBlinkAmpRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'blinkERPAmplitudeRatios_' eegBaseFile];
    saveFigures(hFig9, baseFile, figureFormats, figureClose);
end  

%% Plot box plots of nonblink ERP amplitude ratios
dataLimits = [0, 5];
theTitle = {'Non blink ERP amplitude ratio for preprocessing methods'; eegBaseFile};
theType = 'Amplitude ratio';
hFig10 = makeBlinkRatioBoxPlot(nonBlinkErpAmpRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'nonBlinkERPAmplitudeRatios_' eegBaseFile];
    saveFigures(hFig10, baseFile, figureFormats, figureClose);
end  
