%% Calculate blink event ratios for a 

%% Set up the data
dataDir = 'D:\Research\EEGPipelineProject\dataOut';
EEGBaseFile = 'speedControlSession1Subj2015Rec1';
methodNames = {'LARG', 'MARA', 'ASR_10', 'ASRalt_10', 'ASR_5', 'ASRalt_5'};
numMethods = length(methodNames);
useLogSpectra = false;
inRange = [-1, 1];
outRange = [-2, -1; 1, 2];

%% Read in the files
eegs = cell(numMethods, 1);
for m = 1:numMethods
    fileName = [dataDir filesep EEGBaseFile '_' methodNames{m} '.set'];
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

%% Now plot box plots of individual blink power ratios
dataLimits = [0, 5];
theTitle = {'Blink power ratio for preprocessing methods'; EEGBaseFile};
theType = 'Power ratio';
f = [];
hFig1 = makeBlinkRatioBoxPlot(blinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Non blink power ratio for preprocessing methods'; EEGBaseFile};
theType = 'Power ratio';
hFig2 = makeBlinkRatioBoxPlot(nonBlinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Blink amplitude ratio for preprocessing methods'; EEGBaseFile};
theType = 'Amplitude ratio';
f = [];
hFig3 = makeBlinkRatioBoxPlot(blinkAmpRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Non blink amplitude ratio for preprocessing methods'; EEGBaseFile};
theType = 'Amplitude ratio';
hFig4 = makeBlinkRatioBoxPlot(nonBlinkAmpRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Blink power ratio for preprocessing methods'; EEGBaseFile};
theType = 'Sqrt power ratio';
f = @sqrt;
hFig5 = makeBlinkRatioBoxPlot(blinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Non blink power ratio for preprocessing methods'; EEGBaseFile};
theType = 'Sqrt power ratio';
hFig6 = makeBlinkRatioBoxPlot(nonBlinkPowerRatios, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);

%% Now plot boxplots of ERP blink ratios
dataLimits = [0, 20];
theTitle = {'Blink ERP power ratio for preprocessing methods'; EEGBaseFile};
theType = 'ERP power ratio';
f = [];
hFig7 = makeBlinkRatioBoxPlot(erpBlinkPowerRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 20];
theTitle = {'Non blink ERP power ratio for preprocessing methods'; EEGBaseFile};
theType = 'ERP power ratio';
hFig8 = makeBlinkRatioBoxPlot(nonBlinkErpPowerRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Blink ERP amplitude ratio for preprocessing methods'; EEGBaseFile};
theType = 'Amplitude ratio';
f = [];
hFig9 = makeBlinkRatioBoxPlot(erpBlinkAmpRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
dataLimits = [0, 5];
theTitle = {'Non blink ERP amplitude ratio for preprocessing methods'; EEGBaseFile};
theType = 'Amplitude ratio';
hFig10 = makeBlinkRatioBoxPlot(nonBlinkErpAmpRatio, methodNames, ...
            channelLabels, theTitle, theType, dataLimits, f);
