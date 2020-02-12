%% Create the random spectral points for the common channels

%% Set up the folders
uuidFolder = 'D:\Papers\Current\LARGIIDataCatalogInfo\uuidMaps';
saveFolder = 'D:\Papers\Current\LARGIIDataCatalogInfo\channelSpectragram';
baseFolders = {'O:\LARGDataCorrected', 'H:\LARGDataMaraCorrected', ...
    'H:\LARGDataAsr_10_AggressiveCorrected', ...
    'H:\LARGDataAsr_5_AggressiveCorrected'};
typeNames = {'Larg', 'Mara', 'Asr_10', 'Asr_5'};
numTypes = length(typeNames);
runName = 'run_12';
recalculate = true;
amplitudeName = ['channel' filesep 'amplitudeInfo.mat'];

%% Parameters
freqRange = [2, 30]; 
numFreqs = 50;
wname = 'cmor1-1.5';
freqBands = [2, 4; 4, 7; 7, 12; 12, 30];
freqBandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'}; 
numFreqBands = size(freqBands, 1);

%% Make sure that the save folder exists
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end

%% Make sure covariance folder exists
uuidMaps = cell(numTypes, 1);
for m = 1:numTypes
    uuidName = [uuidFolder filesep typeNames{m} '_UUIDMap.mat'];
    if ~exist(uuidName, 'file')
        error('%s uuid map does not exist', typeNames{m});
    end
    temp = load(uuidName);
    uuidMaps{m} = temp.uuidMap;
end

%% Study info: dir inst site, shortName, studyTitle
removedStudies = {'RSVP', 'RWN_VDE', 'FLERP', 'VEP'};
[studies, meanings] = getStudies(removedStudies, false);
numStudies = size(studies, 1);
studyRootPos = find(strcmpi(meanings, 'studyRoot'), 1, 'first');
studyNamePos = find(strcmpi(meanings, 'studyName'), 1, 'first');

%% Setup the recording map.
template = struct('uuid', NaN, 'site', NaN, 'study', NaN, 'labId', NaN, ...
    'srate', NaN, 'frequencies', NaN, 'scales', NaN, ...
    'correlations', NaN, 'bandCorrelations', NaN);

%% Set up the channels and covariance template
commonChannels = getCommonLabels();
numChans = length(commonChannels);
for n = 1:numStudies
    %% Setup up the folders and see if the results have already been calculated
    studyName = studies{n, studyNamePos};
    studyRoot = studies{n, studyRootPos};
    fprintf('\nStarting %s\n', studyName);
    catalogs = cell(numTypes, 1);
    studyFolders = cell(numTypes, 1);
    for m = 1:numTypes
        runFolder = [baseFolders{m} filesep studyRoot filesep runName];
        studyFolders{m} = [runFolder filesep studyName];
        catalogFolder = [runFolder filesep 'catalog'];
        if ~exist(runFolder, 'dir') || ~exist(studyFolders{m}, 'dir') || ...
                ~exist(catalogFolder, 'dir')
            error(['run folder [%s]\n  studyOutput folder [%s]\n and ' ...
                'catalog [%s] must exist from stage 1'], ...
                runFolder, studyFolders{m}, catalogFolder);
        end
        
        %% Open the catalog and get the file information
        catalogs{m} = EntityCatalog([catalogFolder filesep 'database_catalog.sto']);
    end
    
    %% Allocate space for the study structures
    EEGFiles = filesAndFolders_to_list(studyFolders{m}, {'EEG.set'}, true);
    numRecordings = length(EEGFiles);
    spectrogramRecs = template;
    spectrogramRecs(numRecordings) = template;
    for k = 1:numRecordings
        %% Read the EEG file and the amplitude file fill in the template
        spectrogramRecs(k) = template;
        fprintf('Processing recording %d:%s\n', k, EEGFiles{k});
        [thePath, theName, theExt] = fileparts(EEGFiles{k});
        if exist([thePath filesep 'channel' filesep 'skipMe.txt'], 'file')
            warning('%d %s: should be skipped', k, thePath);
            continue;
        end
        if ~exist([thePath filesep amplitudeName], 'file')
            warning('%d %s: has no amplitude file', k, thePath);
            continue;
        end
        %% Make sure that the dataID is in all types
        temp = load([thePath filesep amplitudeName]);
        amplitudeInfo = temp.amplitudeInfo;
        dataID = amplitudeInfo.custom.sourceDataRecordingId;
        badMask = false;
        for m = 1:numTypes
            if ~isKey(uuidMaps{m}, dataID)
                warning('%s: not in type %s\n', EEGFiles{k}, typeNames{m});
                badMask = true;
                continue;
            end
        end
        if badMask
            continue;
        end
        
        EEGs = cell(numTypes, 1);
        huberMean = nan(numTypes, 1);
        for m = 1:numTypes
            uuidRec = uuidMaps{m}(dataID);
            eegFolder = [studyFolders{m} filesep 'recording_' ...
                num2str(uuidRec.recording)];
            EEGFile = [eegFolder filesep 'EEG.set'];
            EEGs{m} = pop_loadset(EEGFile);
            EEGs{m}= reorderChannels(EEGs{m}, commonChannels);
            EEGs{m} = pop_reref(EEGs{m}, []);
            temp = load([eegFolder filesep amplitudeName]);
            amplitudeInfo = temp.amplitudeInfo;
            huberMean(m) = huber_mean(amplitudeInfo.channelRobustStd.tensor);
            if uuidRec.srate ~= EEGs{m}.srate || ...
                    EEGs{1}.srate ~= EEGs{m}.srate || ...
                    uuidRec.frames ~= size(EEGs{m}.data, 2) || ...
                    size(EEGs{1}.data, 2) ~= size(EEGs{m}.data, 2)
                warning('%s %s does not have matching srate or frames', ...
                    EEGFile, typeNames{m});
                badMask = true;
                break;
            end
        end
        if badMask
            continue;
        end
        uuidRec = uuidMaps{1}(dataID);
        spectrogramRecs(k).uuid = dataID;
        spectrogramRecs(k).srate = uuidRec.srate;
        spectrogramRecs(k).labId = uuidRec.labId;
        spectrogramRecs(k).site = uuidRec.site;
        spectrogramRecs(k).study = uuidRec.study;
        T = 1/EEGs{1}.srate;
        [tScales, tFreqs] = freq2scales(freqRange(1), freqRange(2), numFreqs, wname, T);
        
        [~, sortIds] = sort(tFreqs, 'ascend');
        scales = tScales(sortIds);
        freqs = tFreqs(sortIds);
        tfdecomp = cell(numChans, numTypes);
        for m = 1:numTypes
            EEGs{m}.data = EEGs{m}.data./huberMean(m);
            for c = 1:numChans
                tfd = cwt(EEGs{m}.data(c, :)', scales, wname);   
                tfd = abs(tfd);  % convert to amplitudes
                baselineMedian = median(tfd, 2);
                tfd = bsxfun(@minus, tfd, baselineMedian);
                baselineRobustStd = median(abs(tfd), 2) * 1.4826;
                tfdecomp{c, m} = bsxfun(@times, tfd, 1./ baselineRobustStd);  
            end
        end
        freqMasks = false(numFreqs, numFreqBands);
        for f = 1:numFreqBands
            freqMasks(:, f) = freqBands(f, 1) <= freqs & freqs < freqBands(f, 2);
        end
        numTimes = size(tfdecomp{1, 1}, 2);
        
        %% Now assemble the data into a single vector and into bands
        tfs = zeros(numFreqs*numTimes, numChans, numTypes);
        tfsBands = zeros(numTimes, numChans, numTypes, numFreqBands);
        for m = 1:numTypes
           for c = 1:numChans
               tf = tfdecomp{c, m};
               tfs(:, c, m) = tf(:);
               for f = 1:numFreqBands
                 tfsBands(:, c, m, f) = mean(tf(freqMasks(:, f), :), 1);
               end
           end
        end
        
        %% Compute the average spectra
        spectrogramRecs(k).frequencies = freqs;
        spectrogramRecs(k).scales = scales;
        
        %% Compute the correlations
        spectra= reshape(tfs, numTimes*numFreqs*numChans, numTypes);
        spectrogramRecs(k).correlations = corr(spectra);
        bandCorrelations = cell(numFreqBands, 1);
        spectraBands = reshape(tfsBands, numTimes*numChans, numTypes, numFreqBands);
        for f = 1:numFreqBands
            bandCorrelations{f} = corr(squeeze(spectraBands(:, :, f)));
        end
        spectrogramRecs(k).bandCorrelations = bandCorrelations;
        
    end
    save([saveFolder filesep studyName '_spectrogramCorrelationsAcrossMethods.mat'], ...
        'spectrogramRecs', 'studies', 'typeNames', 'commonChannels', ...
        'freqs', 'scales', 'freqBands', 'freqBandNames', ...
        'freqBandNames'); 
end