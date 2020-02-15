%% Create the random spectral points for the common channels
function [spectrogram, freqs] = getSpectrogram(EEG, channels, numFreqs, freqRange)
%% Compute EEG robust z-scaled spectragram 
%
%  Parameters:
%      EEG           EEG set structure
%      channels      Cell array of labels of channels in the spectragram
%      numFreqs      Number of frequencies in the spectragram
%      freqRange     1 x 2 array with smallest and largest frequency in print
%      spectragram  (output) freqs x times x channels array with spectragram
%      freqs        (output) vector of frequencies
%
%  Note: If EEG does not have all the channels, spectragram is empty
%

%% Check channels are all there and return empty if not
[EEGNew, missing] = selectEEGChannels(EEG, channels);
if ~isempty(missing)
    warning('EEG is missing channels %s\n-- can not compute spectragram', ...
            getListString(missing, ','));
    spectrogram = [];
    freqs = [];
    return;
end

%% Compute the wavelet scales using Morlet wavelets
T = 1/EEGNew.srate;
wname = 'cmor1-1.5';
[tScales, tFreqs] = freq2scales(freqRange(1), freqRange(2), numFreqs, wname, T);
[~, sortIds] = sort(tFreqs, 'ascend');
scales = tScales(sortIds);
freqs = tFreqs(sortIds);

%% Perform the time-frequency decomposition using wavelets and robust z-score
data = EEGNew.data;
numTimes = size(data, 2);
numChans = length(channels);
spectrogram = zeros(numFreqs, numTimes, numChans);
for c = 1:numChans
    tfd = cwt(data(c, :)', scales, wname);
    tfd = abs(tfd);  % convert to amplitudes
    baselineMedian = median(tfd, 2);
    tfd = bsxfun(@minus, tfd, baselineMedian);
    baselineRobustStd = median(abs(tfd), 2) * 1.4826;
    spectrogram(:,:, c) = bsxfun(@times, tfd, 1./ baselineRobustStd);
end
