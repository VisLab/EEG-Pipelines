%% This script runs the Asr pipeline on available studies to remove artifacts

%% Set up the directories
%varRootDir = 'D:\TestData\ASRData\128Hz';
varRootDir = 'D:\TestData\Level1WithBlinks';
asrBase = 'D:\TestData\ASRData\AsrFromLevel1_';
finishedFileNameAsr = 'finishedAsr.mat';
skipMeFileName = 'skipMe.txt';
noBlinksFileName = 'noBlinks.txt';
badAsrFileName = 'badAsr.txt';
runName = 'run_12';
EEGName = 'EEG.set';
noRewrite = false;
%burstCriterion = 10;
burstCriterion = 5;
resamplingFrequency = 128;
capType
%% Since there are several versions of ASR in the path, use ESS one
asrPath = fileparts(which('uniqe_file_to_test_ESS_path'));

%% Make sure the asrRoot folder exists
asrRootDir = [asrBase num2str(burstCriterion)];
if ~exist(asrRootDir, 'dir')
    mkdir(asrRootDir);
end

% %% Set up the studies
% excludedStudies = {'ACC', 'AdvancedGuardDuty', 'AuditoryCueing', ...
%                    'BaselineDriving', 'BasicGuardDuty', ...
%                    'CalibrationDriving', 'DAS', 'DD', 'FLERP', ...
%                    'ICB_CT2WS', 'ICB_RSVP', 'LKwAF', ...
%                    'MindWandering', 'RSVP', 'RSVPA', ...
%                    'RSVPBaseline', 'RSVPExpertise', ...
%                    'SpeedControl', 'TrafficComplexity', 'VEP'};
% [studies, meanings] = getStudies(excludedStudies, false);
% studyRootPos = find(strcmpi(meanings, 'studyRoot'), 1, 'first');
% studyNamePos = find(strcmpi(meanings, 'studyName'), 1, 'first');
% capTypePos = find(strcmpi(meanings, 'capType'), 1, 'first');
% numStudies = size(studies, 1);

%% Now process the studies
errorMsgs = {};
infoMsgs = {};

%% EEG options: no ICA activations, use double precision, and use a single file
pop_editoptions('option_single', false, 'option_savetwofiles', false, ...
    'option_computeica', false);

%% Start the feature diary file
diary([channelFolder filesep 'diaryAsr.txt']);
diary on;
fprintf('Removing artifacts from study %s cap type %s\n', studyName, capType);

%% Load the needed files
EEG = pop_loadset(fileName);

%% Fix the channels and HED tag syntax
chanlocs = EEG.chanlocs;
chanMask = true(1, length(chanlocs));
for m = 1:length(chanMask)
    if ~strcmpi(chanlocs(m).type, 'EEG') || ...
            isempty(chanlocs(m).theta) || isnan(isempty(chanlocs(m).theta))
        chanMask(m) = false;
    end
end
EEG.chanlocs = chanlocs(chanMask);
EEG.data = EEG.data(chanMask, :);
EEG.nbchan = sum(chanMask);

if size(EEG.data,1) > 256
    error('%s: has too many channels', fileNames{k});
elseif size(EEG.data,1) > 128
    EEG = convertEEGFromBiosemi256ToB64(EEG, capType, false);
    warning('Converting from Biosemi256 to Biosemi64: %s', fileNames{k});
end
channelNamingSystem = '10-20';

if size(EEG.data, 1) > 64
    error('%s: has too many channels should be down to 64', fileNames{k});
end
chanlocsOriginal = EEG.chanlocs;
if ~isempty(resamplingFrequency) && EEG.srate > resamplingFrequency
    EEG = pop_resample(EEG, resamplingFrequency);
end

%% Compute channel and global amplitudes before Asr
fprintf(['Computing channel amplitudes (robust standard deviations) ' ...
    'before artifact activity removal..\n']);
EEGLowpassedBeforeAsr = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
EEGLowpassedBeforeAsr.icaact = [];
amplitudeInfoBeforeAsr.allDataRobustStd = ...
    std_from_mad(vec(EEGLowpassedBeforeAsr.data));
channelRobustStd = zeros(size(EEGLowpassedBeforeAsr.data, 1), 1);
for i=1:size(EEGLowpassedBeforeAsr.data, 1)
    channelRobustStd(i) = ...
        median(abs(EEGLowpassedBeforeAsr.data(i,:)' ...
        - median(EEGLowpassedBeforeAsr.data(i,:), 2))) * 1.4826;
end
channelAxis = ChannelAxis('chanlocs', ...
    EEGLowpassedBeforeAsr.chanlocs, 'namingSystem', channelNamingSystem);
amplitudeInfoBeforeAsr.channelRobustStd = ...
    Block('tensor', vec(channelRobustStd), 'axes', {channelAxis});
dataRecording = dataRecordings{k};
dataRecording.custom.sourceDataRecordingId = dataRecordingUuids{k};
asrCatalog.saveEntities(dataRecording, ...
    [channelFolder filesep 'dataRecording.sto']);

amplitudeInfoBeforeAsr.custom.sourceDataRecordingId = ...
    dataRecordingUuids{k};
save([channelFolder filesep 'amplitudeInfoBeforeAsr.mat'], ...
    'amplitudeInfoBeforeAsr', '-v7.3');
clear EEGLowpassedBeforeAsr

%% Save the catalog before continuing
recordingRun.catalogSaveClock.start = clock;
asrCatalog.saveCatalog;
recordingRun.catalogSaveClock.end = clock;

%% Now compute Asr
currentPath = pwd;
cd(asrPath)
try
    %% Do the ASR computation
    recordingRun.asrComputation.start = clock;
    EEG = clean_artifacts(EEG, 'FlatlineCriterion', 5, ...
        'ChannelCriterion',0.8, 'LineNoiseCriterion', 4, ...
        'Highpass', [0.25 0.75],'BurstCriterion', burstCriterion, ...
        'WindowCriterion','off','BurstRejection','off');
    
    recordingRun.asrComputation.end = clock;
catch mex
    cd(currentPath);
    asrError = ['ASR failed: [' mex.message ']'];
    save([channelFolder filesep badAsrFileName], 'asrError', '-ascii');
    errorMsgs{end + 1} = sprintf( ...
        '%d(%d): %s %s', n, k, studyName, asrError); %#ok<*SAGROW>
    warning(errorMsgs{end});
    diary off;
    continue;
end

%% Check to make sure that all of the channels are there
if length(EEG.chanlocs) ~= length(chanlocsOriginal)
    oldLabels = {chanlocsOriginal.labels};
    newLabels = {EEG.chanlocs.labels};
    interpolatedChannels = setdiff(oldLabels, newLabels);
    fprintf('%s: %d channels interpolated', fileNames{k}, ...
        length(interpolatedChannels));
    EEG.etc.interpolatedChannels = interpolatedChannels;
    
end

%% Save the cleaned file
EEGFileNew = [recordingFolders{k} filesep 'EEG.set'];

pop_saveset(EEG, 'filename', EEGFileNew, 'version', '7.3');

%% Now compute the amplitude vectors for future reference
EEGLowpassedAfterAsr = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
amplitudeInfoAfterAsr.allDataRobustStd = ...
    std_from_mad(vec(EEGLowpassedAfterAsr.data));
channelRobustStd = zeros(size(EEGLowpassedAfterAsr.data, 1), 1);
for i = 1:size(EEGLowpassedAfterAsr.data, 1)
    channelRobustStd(i) = ...
        median(abs(EEGLowpassedAfterAsr.data(i,:)' ...
        - median(EEGLowpassedAfterAsr.data(i,:), 2))) * 1.4826;
end
channelAxis = ChannelAxis('chanlocs', ...
    EEGLowpassedAfterAsr.chanlocs, 'namingSystem', channelNamingSystem);
amplitudeInfoAfterAsr.channelRobustStd = ...
    Block('tensor', vec(channelRobustStd), 'axes', {channelAxis});
amplitudeInfoAfterAsr.custom.sourceDataRecordingId = ...
    dataRecordingUuids{k};
save([channelFolder filesep 'amplitudeInfoAfterAsr.mat'], ...
    'amplitudeInfoAfterAsr', '-v7.3');

cd(currentPath);
recordingRun.wholeRun.end = clock;

%% Write a file to indicate that the save process was finished successfully.
save([channelFolder filesep finishedFileNameAsr], 'recordingRun');
handledFiles(end + 1) = k;
fprintf('\n');
diary off;


%% At the end output the names of recordings that are not finished.
outputHandledStatus(handledFiles, recordingFolders);
handledStudies{n} = handledFiles;


%% Output the error messages
if ~isempty(errorMsgs)
    fprintf('Errors:\n');
    for k = 1:length(errorMsgs)
        fprintf('----%s\n', errorMsgs{k});
    end
else
    fprintf('\nNo errors detected\n');
end