%% Calculate random spectral sample correlations and display in boxplot

%% Set up the data
dataDir = 'D:\Research\EEGPipelineProject\dataOut';
EEGBaseFile = 'speedControlSession1Subj2015Rec1';
methodNames = {'LARG', 'MARA', 'ASR_10', 'ASRalt_10', 'ASR_5', 'ASRalt_5'};
numMethods = length(methodNames);

%% Read in the files
eegs = cell(numMethods, 1);
for m = 1:numMethods
    fileName = [dataDir filesep EEGBaseFile '_' methodNames{m} '.set'];
    eegs{m} = pop_loadset(fileName);
end

%% Spectral parameters
spectraTime = 4;
numSpectra = 100;
freqRange = [1, 50]; 
freqResolution = 256;
fBins = linspace(freqRange(1), freqRange(2), freqResolution);
numFreqs = length(fBins);
freqBands = [2, 4; 4, 7; 7, 12; 12, 30; 30, 50];
freqBandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'; 'Gamma'}; 
numFreqBands = size(freqBands, 1);


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
    spectralRecs = template;
    spectralRecs(numRecordings) = template;
  
    for k = 1:numRecordings
        %% Read the EEG file and the amplitude file fill in the template
        spectralRecs(k) = template;
        fprintf('Processing recording %d:%s\n', k, EEGFiles{k});
        [thePath, theName, theExt] = fileparts(EEGFiles{k});
        if exist([thePath filesep 'channel' filesep 'skipMe.txt'], 'file')
            warning('%d %s: should be skipped', k, thePath);
            continue;
        end
        if ~exist([thePath filesep filesep amplitudeName], 'file')
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
        spectralRecs(k).uuid = dataID;
        spectralRecs(k).srate = uuidRec.srate;
        spectralRecs(k).frames = uuidRec.frames;
        spectralRecs(k).randomNums = rand(numChans, numSpectra);
        spectralRecs(k).labId = uuidRec.labId;
        spectralRecs(k).site = uuidRec.site;
        spectralRecs(k).study = uuidRec.study;
        spectralRecs(k).huberMean = huberMean;
        %% Now compute the spectra for each
        startingFracs = spectralRecs(k).randomNums;
        sFrames = spectraTime*uuidRec.srate;
        frames = uuidRec.frames;
        actualFrames = frames - sFrames;
        startFrames = ceil(startingFracs*actualFrames);
        endFrames = startFrames + sFrames - 1;
        chanNums = repmat(1:numChans, 1, 100);
        pSpectra = zeros(numChans, numFreqs, numSpectra, numTypes);
        frequencies = zeros(numFreqs, 1);
        for m = 1:numTypes
            EEGs{m}.data = EEGs{m}.data/spectralRecs(k).huberMean(m);
            for j = 1:numSpectra
                data = zeros(numChans, sFrames);
                for c = 1:numChans
                    data(c, :) = EEGs{m}.data(c, startFrames(c,j):endFrames(c, j));
                end   
                [x, f] = pmtm(data', 4, fBins, 128);
                pSpectra(:, :, j, m) = x';
            end
        end
        %% Compute the average spectra
        spectralRecs(k).frequencies = fBins;
        spectralRecs(k).meanPowerSpectra = squeeze(mean(pSpectra, 3));
        pBandSpectra = zeros(numChans, numFreqBands, numSpectra, numTypes);
        for b = 1:numFreqBands
            freqMask = freqBands(b, 1) <= fBins & fBins < freqBands(b, 2);
            for m = 1:numTypes
                for j = 1:numSpectra
                    pBandSpectra(:, b, j, m) = mean(pSpectra(:, freqMask, j, m), 2);
                end
            end
        end
        %% Compute the correlations
        logPSpectra = 10*log10(pSpectra);
        logPBandSpectra = 10*log10(pBandSpectra);
        correlations = zeros(numChans, numSpectra, numTypes, numTypes);
        logCorrelations = zeros(numChans, numSpectra, numTypes, numTypes);
        logSpectralDist = zeros(numChans, numSpectra, numTypes, numTypes);
        bandCorrelations = zeros(numChans, numFreqBands, numTypes, numTypes);
        logBandCorrelations = zeros(numChans, numFreqBands, numTypes, numTypes);
        for m1 = 1:numTypes
            for m2 = 1:numTypes
                for c = 1:numChans
                    spectra1 = squeeze(pSpectra(c, :, :, m1));
                    spectra2 = squeeze(pSpectra(c, :, :, m2));
                    logSpectra1 = squeeze(logPSpectra(c, :, :, m1));
                    logSpectra2 = squeeze(logPSpectra(c, :, :, m2));
                    for j = 1:numSpectra
                        logSpectralDist(c, j, m1, m2) = ...
                            mean(10*log10(spectra1(:, j)./spectra2(:, j)));
                        correlations(c, j, m1, m2) = ...
                             corr(spectra1(:, j), spectra2(:, j));
                    end
                    
                    bSpectra1 = squeeze(pBandSpectra(c, :, :, m1))';
                    bSpectra2 = squeeze(pBandSpectra(c, :, :, m2))';
                    logBSpectra1 = squeeze(logPBandSpectra(c, :, :, m1))';
                    logBSpectra2 = squeeze(logPBandSpectra(c, :, :, m2))';
                    for b = 1:numFreqBands 
                       bandCorrelations(c, b, m1, m2) = ...
                             corr(bSpectra1(:, b), bSpectra2(:, b));
                       logBandCorrelations(c, b, m1, m2) = ...
                             corr(logBSpectra1(:, b), logBSpectra2(:, b));
                    end
                end
            end
        end
        spectralRecs(k).correlations = correlations;  
        spectralRecs(k).logCorrelations = logCorrelations;  
        spectralRecs(k).bandCorrelations = bandCorrelations;  
        spectralRecs(k).logBandCorrelations = logBandCorrelations; 
        spectralRecs(k).logSpectralDist = logSpectralDist;
    end 
    save([saveFolder filesep studyName '_spectralCorrelationsAcrossMethods.mat'], ...
        'spectralRecs', 'studies', 'typeNames', 'commonChannels', ...
        'freqBands', 'freqBandNames', 'fBins')
end



