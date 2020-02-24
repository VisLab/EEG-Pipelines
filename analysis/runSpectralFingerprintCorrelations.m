%% Calculate the spectral finger print correlations across methods for an EEG file

%% Set up the files
dataDir = 'D:\Research\EEGPipelineProject\dataOut';
eegBaseFile = 'basicGuardSession3Subj3202Rec1';
%eegBaseFile = 'dasSession16Subj131004Rec1';
%eegBaseFile = 'speedControlSession1Subj2015Rec1';
%eegBaseFile = 'trafficComplexitySession1Subj2002Rec1';
methodNames = {'LARG', 'MARA', 'ASR_10', 'ASRalt_10', 'ASR_5', 'ASRalt_5'};
numMethods = length(methodNames);

%% Read in the files
eegs = cell(numMethods, 1);
for m = 1:numMethods
    fileName = [dataDir filesep eegBaseFile '_' methodNames{m} '.set'];
    eegs{m} = pop_loadset(fileName);
end

%% Spectral parameters
freqRange = [2, 30]; 
numFreqs = 50;
freqBands = [2, 4; 4, 7; 7, 12; 12, 30];
freqBandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'}; 
channels = getCommonChannelLabels();
numBands = size(freqBandNames, 1);

%% Compute the spectragrams and band prints for the EEG for the different methods
spectrograms = cell(numMethods, 1);
for m = 1:numMethods
    [spectrograms{m}, freqs] = getSpectrogram(eegs{m}, channels, numFreqs, freqRange);
end
freqMasks = getFrequencyMasks(freqs, freqBands);
bandPrints = cell(numMethods, 1);
for m = 1:numMethods
    bandPrints{m} = getSpectralBandPrints(spectrograms{m}, freqMasks);
end

%% Output the correlations
fprintf('Algorithms    All  %s\n', getListString(freqBandNames, '  '));
for m1 = 1:numMethods - 1
    bPrintsm1 = bandPrints{m1};
    for m2 = m1 + 1:numMethods
        fprintf('%s v %s: %8.5f', methodNames{m1}, methodNames{m2}, ...
            corr(spectrograms{m1}(:), spectrograms{m2}(:))); 
        bPrintsm2 = bandPrints{m2};
        for b = 1:numBands
            bP1 = bPrintsm1(:, :, b);
            bP2 = bPrintsm2(:, :, b);
            fprintf(' %8.5f', corr(bP1(:), bP2(:)));
        end
        fprintf('\n');
    end
end
