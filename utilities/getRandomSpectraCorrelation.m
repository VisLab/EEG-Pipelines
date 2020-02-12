function spectralRec = getRandomSpectraCorrelation(EEGs, numSpectra, ...
                               sampleLength, channels, numFreqs, freqRange, ...
                               freqBands)
                     
%% Compute correlation of random
%
%  Parameters:
%     EEGs          cell array with different versions of the same EEG dataset
%     numSpectra    Number of spectral samples to compute
%     sampleLength  Number of seconds in each spectral sample
%     channels      Channel labels of the channels to use
%     numFreqs      
%   

%% Parameters
spectraTime = 4;
numSpectra = 100;
fBins = linspace(1, 50, 256);
numFreqs = length(fBins);
freqBands = [2, 4; 4, 7; 7, 12; 12, 30; 30, 50];
freqBandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'; 'Gamma'};
numFreqBands = size(freqBands, 1);
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

%% Setup the recording map.
template = struct('uuid', NaN, 'site', NaN, 'study', NaN, 'labId', NaN, ...
    'frames', NaN, 'srate', NaN, 'huberMean', NaN, 'randomNums', NaN, ...
    'frequencies', NaN, 'meanPowerSpectra', NaN, 'logSpectralDist', NaN, ...
    'correlations', NaN, 'bandCorrelations', NaN, ...
    'logCorrelations', NaN, 'logBandCorrelations', NaN);

    %% Read the EEG file and the amplitude file fill in the template
    spectralRecs(k) = template;

    %% Make sure that the dataID is in all types
    temp = load([thePath filesep amplitudeName]);
    amplitudeInfo = temp.amplitudeInfo;
    dataID = amplitudeInfo.custom.sourceDataRecordingId;
    badMask = false;
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
    
    
    
