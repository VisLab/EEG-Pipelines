function bandPrints = getSpectralBandPrints(spectrogram, freqMasks)
%% Apply freqMasks to spectrogram to compute mean spectragrams in individual bands
%
%  Parameters:
%     spectrogram    (freqs x times x chans) time-frequency decomposition
%     freqMask       (freqs x bands) mask of frequencies in each band
%     bandPrints     (output)(times x chans x bands) mean spectral time decomposition
%     
%% Compute the spectral band prints
[numFreqs, numTimes, numChans] = size(spectrogram); %#ok<ASGLU>
numFreqBands = size(freqMasks, 2);
bandPrints = zeros(numTimes, numChans, numFreqBands);
for c = 1:numChans
    for f = 1:numFreqBands
        bandPrints(:, c, f) = mean(spectrogram(freqMasks(:, f), :, c), 1);
    end
end