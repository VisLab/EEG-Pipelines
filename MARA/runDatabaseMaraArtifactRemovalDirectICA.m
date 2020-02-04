%% This script runs the Larg I pipeline on a study to remove eye activity
%
%  B256 channels have been corrected in this version

%% Set up the directories
filteredFolder = 'F:\LARG128Hz';
maraFolder = 'O:\MARAICADirect';
shortName = 'RsvpE';
icaType = 'runica';
runName = 'run_12';
maxSamplingRate = 128;
finishedFileMara = 'finishedMARA.mat';
badFileMara = 'badFileMara.mat';
%% Set up the folders
[studies, meanings] = getStudies();
shortNamePos = find(strcmpi(meanings, 'shortName'), 1, 'first');
studyRootPos = find(strcmpi(meanings, 'studyRoot'), 1, 'first');
studyNamePos = find(strcmpi(meanings, 'studyName'), 1, 'first');
capTypePos = find(strcmpi(meanings, 'capType'), 1, 'first');
studyPos = find(strcmpi(studies(:, shortNamePos), shortName), 1, 'first');
studyName = studies{studyPos, studyNamePos};
studyFolder = [filteredFolder filesep studyName];
baseFolder = [maraFolder filesep studies{studyPos, studyRootPos}];
capType = studies{studyPos, capTypePos};

%% Make sure that the database folder and subfolders exist
if ~exist(baseFolder, 'dir')
    mkdir(baseFolder);
end
runFolder = [baseFolder filesep runName];
if ~exist(runFolder, 'dir')
    mkdir(runFolder);
end
studyOutputFolder = [runFolder filesep studyName];
if ~exist(studyOutputFolder, 'dir')
    mkdir(studyOutputFolder);
end

%% Copy this script file in the study folder (for provenance)
srcScript = [mfilename('fullpath') '.m'];
[~, scriptBase] = fileparts(srcScript);
destScript = [studyOutputFolder filesep scriptBase '_script_copy.m'];
copyfile(srcScript, destScript);

%% Create (or load) a catalog specific to this run
catalogFolder = [runFolder filesep 'catalog'];
if ~exist(catalogFolder, 'dir')
    mkdir(catalogFolder);
end
runCatalog = EntityCatalog([catalogFolder filesep 'database_catalog.sto']);

%% Do we need to apply a tag correction file?
%tagCorrectionFilename = '/media/datadrive/larg_data/studies/tag_correction/multi_study_tag_correction.yaml';

%% EEG options: no ICA activations, use double precision, and use a single file
pop_editoptions('option_single', false, 'option_savetwofiles', false, ...
    'option_computeica', false);

%% Now read in the study from a container
studyObj = load_study_container(studyFolder);

%% Only use recordings with 'good' quality data from PREP pipeline
[fileNames, dataRecordingUuids, taskLabel, sessionNumber, dataRecordingNumber] = ...
    studyObj.getFilename('dataQuality', {'Good'});

allFilenames = studyObj.getFilename();
if length(allFilenames) ~= length(fileNames)
    badFiles = setdiff(allFilenames, fileNames);
    warning('%d bad files were skipped:', length(badFiles));
    for k = 1:length(badFiles)
        fprintf('---skipped %s\n', badFiles{k});
    end
end

%% Produce data recordings and order them according to the files.
dataRecordings = DataRecording.extractFromStudy(studyObj);
ord = nan(length(dataRecordingUuids), 1);
for i=1:length(dataRecordingUuids)
    for j=1:length(dataRecordings)
        if strcmp(dataRecordingUuids{i}, dataRecordings{j}.id)
            ord(i) = j;
            break;
        end
    end
end
if any(isnan(ord))
    error('Some files cannot be associated with a data recording');
end
dataRecordings = dataRecordings(ord);
runCatalog = runCatalog.put(dataRecordings);

%% Now step through the recordings and remove eye artifacts
handledFiles = [];
numRecordings = length(dataRecordings);
recordingFolders = cell(numRecordings, 1);
for k = 1:numRecordings
    fprintf('Processing %d of %d.\n', k, numRecordings);
    recordingRun.wholeRun.start = clock;
    recordingFolders{k} = [studyOutputFolder filesep 'recording_' num2str(k)];
    channelFolder = [recordingFolders{k} filesep 'channel'];
    mkdir(recordingFolders{k});
    mkdir(channelFolder);
    
    %% See whether this is a file to skip
    if exist([channelFolder filesep finishedFileMara], 'file')
        warning('---%s: Skipping because eye artifacts already handled', fileNames{k});
        continue;
    end
    
    %% Start the feature diary file
    diary([channelFolder filesep 'diaryEye.txt']);
    diary on;
    fprintf('Removing eyes from study %s cap type %s\n', studyName, capType);
    
    %% Load the needed files
    recordingRun.loadClock.start = clock;
    EEG = pop_loadset(fileNames{k});
    recordingRun.loadClock.end = clock;
    
    %% Fix the channels and HED tag syntax
    EEG = fix_hed_slash_prefix_in_EEG(EEG);
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
        warning('Converting from Biosemi 256 to Biosemi64 using cap %s: %s', ...
                capType, fileNames{k});
    end
    channelNamingSystem = '10-20';
    
    if size(EEG.data, 1) > 64
        error('%s: has too many channels should be down to 64', fileNames{k});
    end
    
    %% Compute channel and global amplitudes before eye removal
    fprintf(['Computing channel amplitudes (robust standard deviations) ' ...
        'before eye activity removal..\n']);
    EEGLowpassedBeforeEyeRemoval = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
    EEGLowpassedBeforeEyeRemoval.icaact = [];
    amplitudeInfoBeforeEyeRemoval.allDataRobustStd = ...
        std_from_mad(vec(EEGLowpassedBeforeEyeRemoval.data));
    channelRobustStd = zeros(size(EEGLowpassedBeforeEyeRemoval.data, 1), 1);
    for i=1:size(EEGLowpassedBeforeEyeRemoval.data, 1)
        channelRobustStd(i) = ...
            median(abs(EEGLowpassedBeforeEyeRemoval.data(i,:)' ...
            - median(EEGLowpassedBeforeEyeRemoval.data(i,:), 2))) * 1.4826;
    end
    channelAxis = ChannelAxis('chanlocs', ...
        EEGLowpassedBeforeEyeRemoval.chanlocs, 'namingSystem', channelNamingSystem);
    amplitudeInfoBeforeEyeRemoval.channelRobustStd = ...
        Block('tensor', vec(channelRobustStd), 'axes', {channelAxis});
    clear EEGLowpassedBeforeEyeRemoval
        
    %% remove eye artifact and blink activity from time-domain (uses EyeCatch)
    recordingRun.eyeActivityRemovalClock.start = clock;
    [EEG, blinkInfo, removalInfo, errorMsgs] = removeArtifactsMara(EEG, 'useICA', true, ...
        'useBlinkEvents', true, 'icaType', ...
        icaType, 'downsampleBeforeICA', false);
    EEG.icaact = [];
    recordingRun.eyeActivityRemovalClock.end = clock;
    
    %% Add the recording ID for tracking purposes and save the data
    fprintf('Saving the results...\n');
    recordingRun.varSaveClock.start = clock;
    cPath = [recordingFolders{k} filesep 'channel' filesep];
    dataRecording = dataRecordings{k};
    dataRecording.custom.sourceDataRecordingId = dataRecordingUuids{k};
    runCatalog.saveEntities(dataRecording, [cPath 'dataRecording.sto']);
    
    amplitudeInfoBeforeEyeRemoval.custom.sourceDataRecordingId = ...
         dataRecordingUuids{k};
    save([cPath 'amplitudeInfoBeforeEyeRemoval.mat'], ...
         'amplitudeInfoBeforeEyeRemoval', '-v7.3');
    
    blinkInfo.custom.sourceDataRecordingId = dataRecordingUuids{k};
    save([cPath 'blinkInfo.mat'], 'blinkInfo', '-v7.3');
    
    removalInfo.custom.sourceDataRecordingId = dataRecordingUuids{k};
    save([cPath 'removalInfo.mat'], 'removalInfo', '-v7.3');
    
    pop_saveset(EEG, 'filename', 'EEG.set', 'filepath', ...
                recordingFolders{k},'savemode', 'onefile', 'version', '7.3'); 
    recordingRun.varSaveClock.end = clock;        
   
    %% Save the catalog
    recordingRun.catalogSaveClock.start = clock;
    runCatalog.saveCatalog;
    recordingRun.catalogSaveClock.end = clock;
    recordingRun.wholeRun.end = clock;
    
    %% Write a file to indicate that the save process was finished successfully.
    if ~isempty(errorMsgs)
        save([channelFolder filesep badFileMara], 'recordingRun', 'errorMsgs');
    else
        save([channelFolder filesep finishedFileMara], 'recordingRun');
        fprintf('\n');
        
        handledFiles(end + 1) = k;    %#ok<SAGROW>
    end
    diary off;
end

%% At the end output the names of recordings that are not finished.
outputHandledStatus(handledFiles, recordingFolders);

%% Also check that all of the stages have been handled
stageFileNames = {['channel' filesep finishedFileMara]};
stageMask = getHandledPipelineStages(recordingFolders, stageFileNames);
handled = sum(stageMask, 1);
for k = 1:size(handled, 2)
    fprintf('%s: %d out of %d are finished\n', stageFileNames{k}, ...
        handled(k), length(recordingFolders));
end