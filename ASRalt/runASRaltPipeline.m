%% This script runs the underlying subspace removal mechanism of ASR to remove

%% Set up the general processing parameters
dataDirIn = 'D:\Research\EEGPipelineProject\dataIn';
dataDirOut = 'D:\Research\EEGPipelineProject\dataOut';
eegFile = 'speedControlSession1Subj2015Rec1.set';
algorithm = 'ASRalt';
maxSamplingRate = 128;
highPassFrequency = 1.5;
capType = '';
interpolateBadChannels = true;
excludeChannels = {}; % List channel names of mastoids or other non-scalp channels
blinkEventsToAdd = {'maxFrame', 'leftZero', 'rightZero', 'leftBase', ...
                   'rightBase', 'leftZeroHalfHeight', 'rightZeroHalfHeight'};
               
%% Parameter settings specific for ASR
burstCriterion = 5;

%% Make sure output directory exists
if ~exist(dataDirOut, 'dir')
    mkdir(dataDirOut);
end

%% EEG options: no ICA activations, use double precision, and use a single file
pop_editoptions('option_single', false, 'option_savetwofiles', false, ...
    'option_computeica', false);

%% Load the EEG file
[thePath, theName, theExt] = fileparts(eegFile);
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

%% Perform PREP to remove line noise, robust ref, and interpolate bad channels
chanlocs = EEG.chanlocs;
allEEGLabels = {chanlocs.labels};
allEEGChannels = 1:length(allEEGLabels);
allScalpChannels = allEEGChannels;
if ~isempty(excludeChannels)
    [commonLabels, indAll] = intersect(allEEGChannels, excludeChannels);
    allScalpChannels(indAll) = [];
end
params = struct();
paramsInit.detrendType = 'high pass';
paramsInit.detrendCutoff = 1;
paramsInit.referenceType = 'robust';
paramsInit.meanEstimateType = 'median';
paramsInit.interpolationOrder = 'post-reference';
paramsInit.removeInterpolatedChannels = false;
paramsInit.keepFiltered = false;
params.referenceChannels = allScalpChannels;
params.evaluationChannels = allScalpChannels;
params.rereferencedChannels = allEEGChannels;
params.detrendChannels = params.rereferencedChannels;
params.lineNoiseChannels = params.rereferencedChannels;
params.name = theName;
params.ignoreBoundaryEvents = true; % ignore boundary events
EEG = prepPipeline(EEG, params);

%% If a reduction of channels (only Biosemi256 to Biosemi64 is supported)
if strcmpi(capType, 'Biosemi256')
    EEG = convertEEGFromBiosemi256ToB64(EEG, capType, false);
    warning('Converting from Biosemi256 to Biosemi64: %s', fileName);
elseif size(EEG.data > 64, 1)
    warning('The original LARG pipeline remapped to 64 channels in 10-20 config');
end

%% Remove channel mean, filter, and resample if necessary
EEG = filterAndResample(EEG, highPassFrequency, maxSamplingRate);

%% Now run Blinker to insert blink events
params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG));
params.fileName = eegFile;
params.signalNumbers = 1:length(EEG.chanlocs);
params.dumpBlinkerStructures = false;
params.dumpBlinkImages = false;
params.dumpBlinkPositions = false;
params.keepSignals = false;      % Make true if combining downstream
params.showMaxDistribution = false;
params.verbose = false;

% defFigVisibility = get(0, 'DefaultFigureVisible');
% set(0, 'DefaultFigureVisible', figuresVisible)
[EEG, com, blinks, fits, props, stats, params] = pop_blinker(EEG, params);
% set(0, 'DefaultFigureVisible', defFigVisibility)

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

%% Compute channel and global amplitudes before
fprintf('Computing channel amplitudes before ASR ...\n');
EEGLowpassed = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfoBefore.allDataRobustStd = stdFromMad(vec(EEGLowpassed.data));
channelRobustStd = zeros(size(EEGLowpassed.data, 1), 1);
for i=1:size(EEGLowpassed.data, 1)
    channelRobustStd(i) = median(abs(EEGLowpassed.data(i,:)' ...
        - median(EEGLowpassed.data(i,:), 2))) * 1.4826;
end
amplitudeInfoBefore.channelRobustStd = channelRobustStd;
EEG.etc.amplitudeInfoBeforeLARG = amplitudeInfoBefore;
clear EEGLowPassed;

%% Use subspace removal to remove the artifacts
EEG = clean_asr(EEG, burstCriterion);

%% Now compute the amplitude vectors after ASR
fprintf('Computing channel amplitudes after LARG ...\n');
EEGLowpassed = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfo = struct();
amplitudeInfo.allDataRobustStd = stdFromMad(vec(EEGLowpassed.data));
channelRobustStd = zeros(size(EEGLowpassed.data, 1), 1);
for i = 1:size(EEGLowpassed.data, 1)
    channelRobustStd(i) = median(abs(EEGLowpassed.data(i,:)' ...
        - median(EEGLowpassed.data(i,:), 2))) * 1.4826;
end
amplitudeInfo.channelRobustStd = channelRobustStd;
amplitudeInfo.custom.sourceDataRecordingId = EEG.etc.dataRecordingUuid;
EEG.etc.amplitudeInfoAfterLARG = amplitudeInfo;
clear EEGLowpassed;

%% Now save the files
outName = [dataDirOut filesep theName '_' algorithm];
pop_saveset(EEG, 'filename', [outName '.set'], 'version', '7.3');
save([outName '_blinkInfo.mat'], 'blinkInfo', '-v7.3');
