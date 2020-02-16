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
channels = getCommonChannelLabels();
numChans = length(channels);

%% Calculate the event blink and non-blink ratios
blinkPowerRatios = cell(numMethods, 1);
nonBlinkPowerRatios = cell(numMethods, 1);
blinkAmpRatios = cell(numMethods, 1);
nonBlinkAmpRatios = cell(numMethods, 1);
for m = 1:numMethods
    [EEG, missing, selectMask] = selectEEGChannels(eegs{m}, channels);
    if ~isempty(missing)
        warning('EEG is missing channels %s\n-- can not compute spectral fingerprints', ...
            getListString(missing, ','));
        continue;
    end
    
    %% Now calculate the ratios
    [blinkPowerRatios{m}, nonBlinkPowerRatios{m}, blinkAmpRatios{m},  ...
           nonBlinkAmpRatios{m}] = getEEGBlinkRatios(EEG, inRange, outRange);

end
 