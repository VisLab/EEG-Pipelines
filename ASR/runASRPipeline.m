%% This script runs the ASR pipeline on available studies to remove artifacts

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
params.dumpBlinkerStructures = false;
%params.blinkerDumpDir = blinkIndDir;
params.dumpBlinkImages = false;
params.dumpBlinkPositions = false;
params.keepSignals = false;      % Make true if combining downstream
params.showMaxDistribution = true;
params.verbose = false;
[EEG, com, blinks, fits, props, stats, params] = pop_blinker(EEG, params);

%% Save the blinkInfo for downstream analysis
blinkInfo = struct();
blinkInfo.blinks = blinks;
blinkInfo.blinkFits = fits;
blinkInfo.blinkProperties = props;
blinkInfo.blinkStatistics = stats;
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

%% Compute channel and global amplitudes before ASR
fprintf('Computing channel amplitudes before ASR ...\n');
EEGLowpassed = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfo = struct();
amplitudeInfo.allDataRobustStd = std_from_mad(vec(EEGLowpassed.data));
channelRobustStd = zeros(size(EEGLowpassed.data, 1), 1);
for i=1:size(EEGLowpassed.data, 1)
    channelRobustStd(i) = median(abs(EEGLowpassed.data(i,:)' ...
                          - median(EEGLowpassed.data(i,:), 2))) * 1.4826;
end
amplitudeInfo.channelRobustStd = channelRobustStd;
EEG.etc.amplitudeInfoBeforeASR = amplitudeInfo;
clear EEGLowpassed;

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
    fprintf('%s: %d channels interpolated', eegFile, ...
        length(interpolatedChannels));
    EEG = eeg_interp(EEG, chanlocsOriginal, 'spherical');
    EEG.etc.interpolatedChannels = interpolatedChannels; 
end

%% Now compute the amplitude vectors after ASR for future reference
fprintf('Computing channel amplitudes after ASR ...\n');
EEGLowpassed = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfo = struct();
amplitudeInfo.allDataRobustStd = std_from_mad(vec(EEGLowpassed.data));
channelRobustStd = zeros(size(EEGLowpassed.data, 1), 1);
for i = 1:size(EEGLowpassed.data, 1)
    channelRobustStd(i) = median(abs(EEGLowpassed.data(i,:)' ...
        - median(EEGLowpassed.data(i,:), 2))) * 1.4826;
end
amplitudeInfo.channelRobustStd = channelRobustStd;
amplitudeInfo.custom.sourceDataRecordingId = EEG.etc.dataRecordingUuid;
EEG.etc.amplitudeInfoAfterASR = amplitudeInfo;

%% Now save the files
[thePath, theName, theExt] = fileparts(eegFile);
outName = [dataDirOut filesep theName '_' algorithm];
pop_saveset(EEG, 'filename', [outName '.set'], 'version', '7.3');
save([outName '_blinkInfo.mat'], 'blinkInfo', '-v7.3');
