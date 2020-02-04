%% Added blink events to level 1 NCTU_RWN_VDE

%% Set up the directories
study = 'NCTU_RWN_VDE';
level1Dir = 'D:\TestData\Level1WithBlinks\NCTU_RWN_VDE';
infoDir = [level1Dir filesep 'additional_documentation'];
blinkDir = [infoDir filesep 'blinks'];
typeBlinks = 'Level1MastRefCombinedWithDate';
blinkIndDir = [blinkDir filesep typeBlinks];
dataDir = [level1Dir filesep 'session'];
baseFile = 'eeg_NCTU_RWN_VDE_session_';
fieldList = {'maxFrame', 'leftZero', 'rightZero', 'leftBase', 'rightBase', ...
             'leftZeroHalfHeight', 'rightZeroHalfHeight'};

newBlinkDir = 'D:\TestData\Level1WithBlinks\NCTU_RWN_VDE\additional_documentation\blinks';
newBlinkFile = [newBlinkDir filesep 'NCTU_RWN_VDE_BlinkFileListLevel1.mat'];  
ess1File = 'study_description.xml';
%% Load the blinkFile list and create a UUID map
temp = load(newBlinkFile);
blinkFiles = temp.blinkFiles;

%% Get the ess representation
ess1Path = [level1Dir filesep ess1File];
obj1 = level1Study(ess1Path);
[fileNames, dataRecodingUuids, taskLabels, sessions] = obj1.getFilename();
sessionMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
for k = 1:length(sessions)
    sessionMap(sessions{k}) = dataRecodingUuids{k};
end

%% Load the list of individual blink files
blinkFileList = filesAndFolders_to_list(blinkIndDir,{'*.mat'}, true);
numFiles = length(blinkFileList);

%% Now process the blinks files
for k = 1:numFiles
    temp = load(blinkFileList{k});
    blinkInfo = struct();
    blinkInfo.blinks = temp.blinks;
    blinkInfo.blinkFits = temp.blinkFits;
    blinkInfo.blinkProperties = temp.blinkProperties;
    blinkInfo.blinkStatistics = temp.blinkStatistics;
    blinkInfo.blinkSignal = [];
    blinkInfo.custom = [];
    %% Get the eeg file path
    blinks = temp.blinks;
    eegFile = blinks.fileName;
    uniqueName = blinks.uniqueName;
    pieces = strsplit(uniqueName, '_');
    session = pieces{end};
    eegPath = [dataDir filesep session filesep eegFile];
    EEG = pop_loadset(eegPath);
    EEG.etc.dataRecordingUuid = sessionMap(session);
    blinkInfo.custom.sourceDataRecordingId = sessionMap(session);
    if isnan(blinks.usedSignal)
        warning('%s: %s does not have a blink signal', k, eegFile);
        blinkInfo.custom.blinkChannel = [];
        blinkSignal = [];
    else
        blinkInfo.custom.blinkChannel = EEG.chanlocs(abs(blinks.usedSignal)).labels;
        [EEG, blinkSignal] = addBlinkEvents(EEG, temp.blinks, ...
                    temp.blinkFits, temp.blinkProperties, fieldList);
    end
    %% Add blink events to the EEG
     blinkInfo.blinkSignal = blinkSignal;
     pop_saveset(EEG, eegPath);
     save([dataDir filesep session filesep 'blinkInfo.mat'], 'blinkInfo', '-v7.3');
end