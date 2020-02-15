function [spectralSamples, freqs] = getRandomSpectralSamples(EEG, startingFracs, ...
                               sampleLength, channels, numFreqs, freqRange)
                     
%% Compute specified random spectral samples
%
%  Parameters:
%     EEG           EEG set structure
%     startingFracs numChans x numSamples array with starting fractions
%     sampleLength  Number of seconds in each spectral sample
%     channels      Cell array of labels of the channels to use
%     numFreqs      Number of frequencies in spectrum
%     freqRange     Frequency range of the spectral samples
%  
%  Note: If EEG does not have all the channels, spectralSamples is empty
%

%% Check channels are all there and return empty if not
[EEGNew, missing] = selectEEGChannels(EEG, channels);
if ~isempty(missing)
    warning('EEG is missing channels %s\n-- can not compute spectral samples', ...
            getListString(missing, ','));
    spectralSamples = [];
    freqs = [];
    return;
end

%% Compute the spectral samples
numSpectra = size(startingFracs, 2);
fBins = linspace(freqRange(1), freqRange(2), numFreqs);
sFrames = sampleLength*EEGNew.srate;
data = EEGNew.data;
[numChans, numFrames] = size(data);
actualFrames = numFrames - sFrames;
startFrames = ceil(startingFracs*actualFrames);
endFrames = startFrames + sFrames - 1;
spectralSamples = zeros(numChans, numFreqs, numSpectra);

for j = 1:numSpectra
    dataSamples = zeros(numChans, sFrames);
    for c = 1:numChans
        dataSamples(c, :) = data(c, startFrames(c,j):endFrames(c, j));
    end
    [x, f] = pmtm(dataSamples', 4, fBins, 128);
    spectralSamples(:, :, j) = x';
end
freqs = f;