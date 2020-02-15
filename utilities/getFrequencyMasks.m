function freqMasks = getFrequencyMasks(freqs, freqBands)
%% Returns the frequency masks for freqs
%
%  Parameters:
%     freqs     f x 1 vector of frequencies in the time-frequency decomposition
%     freqBands n x 2 array of frequency band start and end frequencies
%     freqMask  (output) f x n array of frequency masks for the bands

numFreqs = length(freqs);
numFreqBands = size(freqBands, 1);
freqMasks = false(numFreqs, numFreqBands);
for b = 1:numFreqBands
    freqMasks(:, b) = freqBands(b, 1) <= freqs & freqs < freqBands(b, 2);
end