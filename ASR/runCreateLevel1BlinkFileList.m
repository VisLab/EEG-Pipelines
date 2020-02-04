%% Creates a blinkFileList based on level 1 for NCTU_RWN_VDE

oldBlinkFile = ['E:\LARG128Hz\NCTU_RWN_VDE\additional_data\blinks\' ...
                'NCTU_RWN_VDE_BlinkFileListOriginal.mat'];
           
newBlinkDir = 'D:\TestData\Level1WithBlinks\NCTU_RWN_VDE\additional_documentation\blinks';
newBlinkFile = [newBlinkDir filesep 'NCTU_RWN_VDE_BlinkFileListLevel1.mat'];

%% Make the new blink directory if needed
if ~exist(newBlinkDir, 'dir')
    mkdir(newBlinkDir);
end

%% Load the list from the original 128 Hz version
temp = load(oldBlinkFile);
bFilesOld = temp.blinkFiles;
numFiles = length(bFilesOld);

%% Set up the template
template = struct('fileName', NaN, 'blinkFileName', NaN, ...
                  'subjectID', NaN, 'experiment', NaN, 'uniqueName', NaN, ...
                  'task', NaN, 'startDate', NaN, 'startTime', NaN, ...
                  'session', NaN, 'fatigue', NaN, 'repetition', NaN);
blinkFiles = template;
blinkFiles(numFiles) = template;

%% Process the data
for k = 1:numFiles
    blinkFiles(k) = template;
    blinkFiles(k).fileName = bFilesOld(k).fileName;
    blinkFiles(k).blinkFileName = bFilesOld(k).blinkFileName;
    blinkFiles(k).subjectID = bFilesOld(k).subjectID;
    blinkFiles(k).experiment = bFilesOld(k).experiment;
    blinkFiles(k).uniqueName = bFilesOld(k).uniqueName;
    blinkFiles(k).task = bFilesOld(k).task;
    blinkFiles(k).startDate = bFilesOld(k).startDate;
    blinkFiles(k).startTime = bFilesOld(k).startTime;
    blinkFiles(k).session = bFilesOld(k).session;
    thisName = blinkFiles(k).uniqueName;
    thisTask = blinkFiles(k).task;
    taskPos = strfind(thisName, thisTask);
    splitName = thisName(taskPos + length(thisTask) + 1:end);
    pieces = strsplit(splitName, '_');
    blinkFiles(k).fatigue = pieces{1};
    blinkFiles(k).repetition = pieces{2};
end

%% Now save the file
save(newBlinkFile, 'blinkFiles', '-v7.3');                  


            
            