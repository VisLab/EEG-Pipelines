%% Create the random spectral points for the common channels
function [spectralPrint, bandPrints] = getSpectralFingerprints(EEG, channels,  ...
                                    numFreqs, freqRange, freqBands)
%% Compute EEG spectral fingerprint and spectral band fingerprints
%
%  Parameters:
%      EEG        EEG set structure
%      channels   cell array of labels of channels in the fingerprint
%      numFreqs   number of frequencies in the spectral fingerprints
%      freqRange  1 x 2 array with smallest and largest frequency in print
%      freqBands  n x 2 array with frequencies of the n bands to resolve
%      spectralPrint  (output) freqs x times x channels array with spectral fingerprint
%      bandPrints     (output) times x channels x bands array with band
%                     averaged fingerprints
%% Parameters
wname = 'cmor1-1.5';
numFreqBands = size(freqBands, 1);
numChans = length(channels);
%% Initialize fingerprints and check channels are all there
spectralPrint = [];
bandPrints = [];
[EEGNew, missing] = selectEEGChannels(EEG, channels);
if ~isempty(missing)
    warning('EEG is missing channels %s\n-- can not compute spectral fingerprints', ...
            getListString(missing, ','));
    return;
end
numChannels = length(channels);

%% Compute the wavelet scales
T = 1/EEGNew.srate;
[tScales, tFreqs] = freq2scales(freqRange(1), freqRange(2), numFreqs, wname, T);
[~, sortIds] = sort(tFreqs, 'ascend');
scales = tScales(sortIds);
freqs = tFreqs(sortIds);

%% Perform the time-frequency decomposition using wavelets
tfdecomp = cell(numChannels, 1);
data = EEGNew.data;
for c = 1:numChannels
    tfd = cwt(data(c, :)', scales, wname);
    tfd = abs(tfd);  % convert to amplitudes
    baselineMedian = median(tfd, 2);
    tfd = bsxfun(@minus, tfd, baselineMedian);
    baselineRobustStd = median(abs(tfd), 2) * 1.4826;
    tfdecomp{c} = bsxfun(@times, tfd, 1./ baselineRobustStd);
end

freqMasks = false(numFreqs, numFreqBands);
for f = 1:numFreqBands
    freqMasks(:, f) = freqBands(f, 1) <= freqs & freqs < freqBands(f, 2);
end
numTimes = size(tfdecomp{1, 1}, 2);

%% Now assemble the data into a single vector and into bands
tfs = zeros(numFreqs, numTimes, numChans);
tfsBands = zeros(numTimes, numChans, numFreqBands);
for c = 1:numChans
    tf = tfdecomp{c};
    tfs(:,:, c) = tf;
    for f = 1:numFreqBands
        tfsBands(:, c, f) = mean(tf(freqMasks(:, f), :), 1);
    end
end

spectralPrint = tfs;
bandPrints = tfsBands;
%