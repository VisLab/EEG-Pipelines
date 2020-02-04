%% This script runs the Asr pipeline on available studies to remove artifacts

%% Set up the directories
%varRootDir = 'D:\TestData\ASRData\128Hz';
varRootDir = 'D:\TestData\ASRData\LARG128HzNoInterpolationAggressive';
asrBase = 'D:\TestData\ASRData\Asr_AggressiveNew_';
finishedFileNameAsr = 'finishedAsr.mat';
skipMeFileName = 'skipMe.txt';
noBlinksFileName = 'noBlinks.txt';
badAsrFileName = 'badAsr.txt';
runName = 'run_12';
EEGName = 'EEG.set';
noRewrite = false;
burstCriterion = 10;
%burstCriterion = 5;

%% Since there are several versions of ASR in the path, use ESS one
asrPath = fileparts(which('uniqe_file_to_test_ESS_path'));

%% Make sure the asrRoot folder exists
asrRootDir = [asrBase num2str(burstCriterion)];
if ~exist(asrRootDir, 'dir')
    mkdir(asrRootDir);
end

%% Set up the studies
[studies, meanings] = getStudies();
studyRootPos = find(strcmpi(meanings, 'studyRoot'), 1, 'first');
studyNamePos = find(strcmpi(meanings, 'studyName'), 1, 'first');
capTypePos = find(strcmpi(meanings, 'capType'), 1, 'first');
numStudies = length(studies);

%% Now process the studies
errorMsgs = {};
infoMsgs = {};
handledStudies = cell(numStudies, 1);
for n = 18%:numStudies
    %% Set up the directories
    studyRoot = studies{n, studyRootPos};
    studyName = studies{n, studyNamePos};
    capType = studies{n, capTypePos};
    varStudyDir = [varRootDir filesep studyName];
    if ~exist(varStudyDir, 'dir')
        errorMsgs{end + 1} = sprintf( ...
            '%d: %s does not have variations computed\n', n, studyName); %#ok<*SAGROW>
        warning(errorMsgs{end});
        continue;
    end
    fprintf('Processing %s...\n', studyName);
    
    %% Set up the mara catalog for the study
    asrStudyRootDir = [asrRootDir filesep studyRoot];
    asrStudyDir = [asrStudyRootDir filesep runName filesep studyName];
    asrCatalogDir = [asrStudyRootDir filesep runName filesep 'catalog'];
    if ~exist(asrCatalogDir, 'dir')
        mkdir(asrCatalogDir);
    end
    if ~exist(asrStudyDir, 'dir')
        mkdir(asrStudyDir);
    end
    asrCatalog = EntityCatalog([asrCatalogDir filesep 'database_catalog.sto']);
    
    %% Copy this script to the study directory for provenance
    srcScript = [mfilename('fullpath') '.m'];
    [~, scriptBase] = fileparts(srcScript);
    destScript = [asrStudyDir filesep scriptBase '_script_copy.m'];
    copyfile(srcScript, destScript);
    
    %% Do we need to apply a tag correction file?
    %tagCorrectionFilename = '/media/datadrive/larg_data/studies/tag_correction/multi_study_tag_correction.yaml';
    
    %% EEG options: no ICA activations, use double precision, and use a single file
    pop_editoptions('option_single', false, 'option_savetwofiles', false, ...
        'option_computeica', false);
    
    %% Now read in the study from a container
    studyObj = load_study_container(varStudyDir);
    
    %% Only use recordings with 'good' quality data from PREP pipeline
    [fileNames, dataRecordingUuids, taskLabel, sessionNumber, ...
        dataRecordingNumber] = studyObj.getFilename('dataQuality', {'Good'});
    
    allFilenames = studyObj.getFilename();
    if length(allFilenames) ~= length(fileNames)
        badFiles = setdiff(allFilenames, fileNames);
        warning('%d bad files were skipped:', length(badFiles));
        for k = 1:length(badFiles)
            infoMsgs{end + 1} = ...
                sprintf('---skipped because bad PREP data quality %s\n', badFiles{k});
        end
    end
    
    %% Produce data recordings and order them according to files as with Larg
    dataRecordings = DataRecording.extractFromStudy(studyObj);
    recordingMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    ord = nan(length(dataRecordingUuids), 1);
    for k = 1:length(dataRecordings)
        recordingMap(dataRecordings{k}.id) = k;
    end
    for k = 1:length(dataRecordingUuids)
        if ~isKey(recordingMap, dataRecordingUuids{k})
            error('%s: recording %d is not associated with data recording', ...
                studyName, k);
        end
        ord(k) = recordingMap(dataRecordingUuids{k});
    end
    dataRecordings = dataRecordings(ord);
    asrCatalog = asrCatalog.put(dataRecordings);
    
    %% Now step through the recordings and apply Asr
    handledFiles = [];
    numRecordings = length(dataRecordings);
    recordingFolders = cell(numRecordings, 1);
    for k = 1:numRecordings
        fprintf('Processing %d of %d.\n', k, numRecordings);
        recordingRun.wholeRun.start = clock;
        recordingFolders{k} = [asrStudyDir filesep 'recording_' num2str(k)];
        channelFolder = [recordingFolders{k} filesep 'channel'];
        if ~exist(recordingFolders{k}, 'dir')
            mkdir(recordingFolders{k});
        end
        if ~exist(channelFolder, 'dir')
            mkdir(channelFolder);
        end
        
        %% See whether this is a file to skip
        if exist([channelFolder filesep finishedFileNameAsr], 'file')
            warning('---%s: %s Skipping because eye artifacts already handled', ...
                    studyName, fileNames{k});
            continue;
        end
        
        %% Start the feature diary file
        diary([channelFolder filesep 'diaryAsr.txt']);
        diary on;
        fprintf('Removing artifacts from study %s cap type %s\n', studyName, capType);
        
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
            warning('Converting from Biosemi256 to Biosemi64: %s', fileNames{k});
        end
        channelNamingSystem = '10-20';
        
        if size(EEG.data, 1) > 64
            error('%s: has too many channels should be down to 64', fileNames{k});
        end
        chanlocsOriginal = EEG.chanlocs;
        

        %% Compute channel and global amplitudes before Asr
        fprintf(['Computing channel amplitudes (robust standard deviations) ' ...
            'before artifact activity removal..\n']);
        EEGLowpassedBeforeAsr = pop_eegfiltnew(EEG, [], 20); % lowpassed at 20 Hz
        EEGLowpassedBeforeAsr.icaact = [];
        amplitudeInfoBeforeEyeRemoval.allDataRobustStd = ...
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
        
        %% Now insert blink events and save
        try
           [EEG, blinkInfo] = extractAndAddBlinkEvents(EEG);
           blinkInfo.custom.sourceDataRecordingId = dataRecordingUuids{k};
           save([channelFolder filesep 'blinkInfo.mat'], 'blinkInfo', '-v7.3');
        catch Mex
            blinkError = ['Blinks failed: [' mex.message ']'];
            save([channelFolder filesep noBlinksFileName], 'blinkError', '-ascii');
            fprintf('%s\n', blinkError);
        end

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
            EEG = clean_asr(EEG, burstCriterion);
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
            error('%s:%d  need to interpolate channels', studyName, k);
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
    end
    
    %% At the end output the names of recordings that are not finished.
    outputHandledStatus(handledFiles, recordingFolders);
    handledStudies{n} = handledFiles;
end

%% Output the error messages
if ~isempty(errorMsgs)
    fprintf('Errors:\n');
    for k = 1:length(errorMsgs)
        fprintf('----%s\n', errorMsgs{k});
    end
else
    fprintf('\nNo errors detected\n');
end