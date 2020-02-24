%% Calculate random spectral sample correlations and display in boxplots

%% Set up the data
dataDir = 'D:\Research\EEGPipelineProject\dataOut';
imageDir = 'D:\Research\EEGPipelineProject\dataImages';
%eegBaseFile = 'basicGuardSession3Subj3202Rec1';
%eegBaseFile = 'dasSession16Subj131004Rec1';
eegBaseFile = 'speedControlSession1Subj2015Rec1';
%eegBaseFile = 'trafficComplexitySession1Subj2002Rec1';
methodNames = {'LARG', 'MARA', 'ASR_10', 'ASRalt_10', 'ASR_5', 'ASRalt_5'};
numMethods = length(methodNames);
useLogSpectra = false;

%% Specify the formats in which to save the data
%figureFormats = {'.png', 'png'; '.fig', 'fig'; '.pdf' 'pdf'; '.eps', 'epsc'};
figureFormats = {'.png', 'png'};
figureClose = false;

%% Read in the files
eegs = cell(numMethods, 1);
for m = 1:numMethods
    fileName = [dataDir filesep eegBaseFile '_' methodNames{m} '.set'];
    eegs{m} = pop_loadset(fileName);
end

%% Specify the spectral parameters
sampleLength = 4;
numSpectra = 100;
freqRange = [1, 50]; 
freqResolution = 256;
fBins = linspace(freqRange(1), freqRange(2), freqResolution);
numFreqs = length(fBins);
freqBands = [2, 4; 4, 7; 7, 12; 12, 30; 30, 50];
bandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'; 'Gamma'}; 
numBands = size(freqBands, 1);
channels = getCommonChannelLabels();
numChans = length(channels);

%% Now compute the spectral samples
samples = cell(numMethods, 1);
startingFracs = rand(numChans, numSpectra); % Use same for all methods 
for m = 1:numMethods
    [samples{m}, freqs] = getRandomSpectralSamples(eegs{m}, startingFracs, ...
        sampleLength, channels, numFreqs, freqRange);
end

%% Now assemble into arrays along with bands
freqMasks = getFrequencyMasks(freqs, freqBands);
spectralSamples = zeros(numChans, numFreqs, numSpectra, numMethods);
bandSamples = zeros(numChans, numBands, numSpectra, numMethods);
for m = 1:numMethods
    spectralSamples(:, :, :, m) = samples{m};
    for b = 1:numBands
        freqMask = freqMasks(:, b);
        for j = 1:numSpectra
            bandSamples(:, b, j, m) = mean(spectralSamples(:, freqMask, j, m), 2);
        end
    end
end

%% Compute the correlations
if useLogSpectra
    spectralSamples = 10*log10(spectralSamples); %#ok<*UNRCH>
    bandSamples = 10*log10(bandSamples);
end
numCombos = numMethods*(numMethods - 1)/2;
comboNames = cell(numCombos, 1);
correlations = zeros(numChans, numSpectra, numCombos);
bandCorrelations = zeros(numChans, numBands, numCombos);
k = 0;
for m1 = 1:numMethods - 1
    for m2 = m1 + 1:numMethods
        k = k + 1;
        comboNames{k} = [methodNames{m1} ' vs ' methodNames{m2}];
        for c = 1:numChans
            spectra1 = squeeze(spectralSamples(c, :, :, m1));
            spectra2 = squeeze(spectralSamples(c, :, :, m2));
            for j = 1:numSpectra
                correlations(c, j, k) = ...
                    corr(spectra1(:, j), spectra2(:, j));
            end
            
            bSpectra1 = squeeze(bandSamples(c, :, :, m1))';
            bSpectra2 = squeeze(bandSamples(c, :, :, m2))';
            for b = 1:numBands
                bandCorrelations(c, b, k) = ...
                    corr(bSpectra1(:, b), bSpectra2(:, b));
            end
        end
    end
end

%% Now spectral samples as a box plot
boxValues = reshape(correlations, numChans*numSpectra, numCombos);
[boxValues, boxLabels] = reformatBoxPlotData(boxValues, comboNames);
theTitle = {'Spectral sample correlation by method:'; eegBaseFile};
hFig = makeGroupBoxPlot(boxValues, boxLabels, theTitle, comboNames);
if ~isempty(imageDir)
    baseFile = [imageDir filesep 'SpectralSampleCorr_' eegBaseFile];
    saveFigures(hFig, baseFile, figureFormats, figureClose);
end

%% Now plot the spectral bands as a box plot
hFigs = cell(numBands, 1);
for b = 1:numBands
    boxValues = squeeze(correlations(:, b, :));
    [boxValues, boxLabels] = reformatBoxPlotData(boxValues, comboNames);
    theTitle = {[bandNames{b} ' band correlation by method:']; eegBaseFile};
    hFigs{b} = makeGroupBoxPlot(boxValues, boxLabels, theTitle, comboNames);
    if ~isempty(imageDir)
        baseFile = [imageDir filesep 'SpectralSampleCorr_' bandNames{b} '_' eegBaseFile];
        saveFigures(hFigs{b}, baseFile, figureFormats, figureClose);
    end
end