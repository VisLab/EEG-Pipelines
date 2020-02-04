%% This script runs the Asr pipeline on available studies to remove artifacts

%% Set up the parameters
dataDirIn = 'D:\Research\EEGPipelineProject\dataIn';
dataDirOut = 'D:\Research\EEGPipelineProject\dataOut';
eegFile = 'speedControlSession1Subj2015Rec1.set';
algorithm = 'ASR';
burstCriterion = 5;
resamplingFrequency = 128;
capType = '';
blinkEventsToAdd = {'maxFrame', 'leftZero', 'rightZero', 'leftBase', ...
                   'rightBase', 'leftZeroHalfHeight', 'rightZeroHalfHeight'};
interpolateBadChannels = true;

%% Make sure output directory exists
if ~exist(dataDirOut, 'dir')
    mkdir(dataDirOut);
end

%% EEG options: no ICA activations, use double precision, and use a single file
pop_editoptions('option_single', false, 'option_savetwofiles', false, ...
    'option_computeica', false);

%% Load the EEG file
EEG = pop_loadset([dataDirIn filesep eegFile]);

%% Make sure it has a dataRecordingUuid for identification downstream
if ~isfield(EEG.etc, 'dataRecordingUuid') || isempty(EEG.etc.dataRecordingUuid)
    EEG.etc.dataRecordingUuid = getUuid();
end

%% Remove the non-EEG channels
chanMask = true(1, length(EEG.chanlocs));
for m = 1:length(chanMask)
    if ~strcmpi(EEG.chanlocs(m).type, 'EEG') || ...
        isempty(EEG.chanlocs(m).theta) || isnan(isempty(EEG.chanlocs(m).theta))
        chanMask(m) = false;
    end
end
EEG.chanlocs = EEG.chanlocs(chanMask);
EEG.data = EEG.data(chanMask, :);
EEG.nbchan = sum(chanMask);

%% If a reduction of channels (only Biosemi256 to Biosemi64 is supported)
if strcmpi(capType, 'Biosemi256')
    EEG = convertEEGFromBiosemi256ToB64(EEG, capType, false);
    warning('Converting from Biosemi256 to Biosemi64: %s', fileName);
end

%% If downsampling before processing
if ~isempty(resamplingFrequency) && EEG.srate > resamplingFrequency
    EEG = pop_resample(EEG, resamplingFrequency);
end

%% Now run Blinker to insert blink events
params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG));
params.fileName = eegFile;
params.signalNumbers = 1:length(EEG.chanlocs);
params.blinkerSaveFile = blinkerSaveFile;
params.dumpBlinkerStructures = true;
params.blinkerDumpDir = blinkIndDir;
params.dumpBlinkImages = false;
params.dumpBlinkPositions = false;
params.keepSignals = false;      % Make true if combining downstream
params.showMaxDistribution = true;
params.verbose = false;
[EEG, com, blinks, fits, props, stats, params] = pop_blinker(EEG, params);

%% Save the blinkInfo for downstream analysis
blinkInfo = struct();
blinkInfo.blinks = blinks;
blinkInfo.blinkFits = blinkFits;
blinkInfo.blinkProperties = blinkProperties;
blinkInfo.blinkStatistics = blinkStatistics;
blinkInfo.blinkSignal = [];
blinkInfo.custom = [];
blinkInfo.custom.blinkChannel = '';
blinkInfo.custom.sourceDataRecordingId = EEG.etc.dataRecordingUuid;
if isnan(blinks.usedSignal)
    warning('%s: does not have a blink signal', filename);
else
    blinkInfo.custom.blinkChannel = EEG.chanlocs(abs(blinks.usedSignal)).labels;
    if ~isempty(blinkEventsToAdd)
        [EEG, blinkSignal] = addBlinkEvents(EEG, blinks, ...
            fits, props, blinkEventsToAdd);
        blinkInfo.custom.blinkSignal = blinkSignal;
    end
end

%% Compute channel and global amplitudes before Asr
fprintf(['Computing channel amplitudes (robust standard deviations) ' ...
    'before artifact activity removal..\n']);
EEGLowpassedBefore = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfoBeforeAsr.allDataRobustStd = ...
    std_from_mad(vec(EEGLowpassedBefore.data));
channelRobustStd = zeros(size(EEGLowpassedBefore.data, 1), 1);
for i=1:size(EEGLowpassedBefore.data, 1)
    channelRobustStd(i) = ...
        median(abs(EEGLowpassedBefore.data(i,:)' ...
        - median(EEGLowpassedBefore.data(i,:), 2))) * 1.4826;
end
amplitudeInfoBeforeAsr.channelRobustStd = channelRobustStd;
EEG.etc.amplitudeInfoBeforeAsr = amplitudeInfoBeforeAsr;

%% Now compute Asr
chanlocsOriginal = EEG.chanlocs;
EEG = clean_artifacts(EEG, 'FlatlineCriterion', 5, ...
        'ChannelCriterion',0.8, 'LineNoiseCriterion', 4, ...
        'Highpass', [0.25 0.75],'BurstCriterion', burstCriterion, ...
        'WindowCriterion','off','BurstRejection','off');

%% Check to make sure that all of the channels are there
if interpolateBadChannels && length(EEG.chanlocs) ~= length(chanlocsOriginal)
    oldLabels = {chanlocsOriginal.labels};
    newLabels = {EEG.chanlocs.labels};
    interpolatedChannels = setdiff(oldLabels, newLabels);
    fprintf('%s: %d channels interpolated', fileName, ...
        length(interpolatedChannels));
    EEG = eeg_interp(EEG, chanlocsOriginal, 'spherical');
    EEG.etc.interpolatedChannels = interpolatedChannels; 
end

%% Save the cleaned file
EEGFileNew = [recordingFolders{k} filesep 'EEG.set'];

pop_saveset(EEG, 'filename', EEGFileNew, 'version', '7.3');

%% Now compute the amplitude vectors after ASR for future reference
EEGLowpassedAfterAsr = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfoAfterAsr.allDataRobustStd = ...
    std_from_mad(vec(EEGLowpassedAfterAsr.data));
channelRobustStd = zeros(size(EEGLowpassedAfterAsr.data, 1), 1);
for i = 1:size(EEGLowpassedAfterAsr.data, 1)
    channelRobustStd(i) = ...
        median(abs(EEGLowpassedAfterAsr.data(i,:)' ...
        - median(EEGLowpassedAfterAsr.data(i,:), 2))) * 1.4826;
end
amplitudeInfoAfterAsr.channelRobustStd = channelRobustStd;
amplitudeInfoAfterAsr.custom.sourceDataRecordingId = EEG.etc.dataRecordingUuid;
EEG.etc.amplitudeInfoAfterAsr = amplitudeInfoAfterAsr;

%% Now save the files
[thePath, theName, theExt] = fileparts(fileName);
outName = [dataDirOut filesep outName '_' algorithName];
pop_saveset(EEG, 'filename', [outName '.set'], 'version', '7.3');
save([outName '_blinkInfo.mat'], 'blinkInfo', '-v7.3');
