%% Create the random spectral points for the common channels
function [spectrumPrint, bandPrint] = getSpectralFingerprint(EEG, channels,  ...
                                    numFrequencies, freqRange, freqBands)
%% Compute EEG spectral fingerprint and spectral band fingerprint
%
%  Parameters:

%% Parameters
freqRange = [2, 30]; 
numFreqs = 50;
wname = 'cmor1-1.5';
freqBands = [2, 4; 4, 7; 7, 12; 12, 30];
freqBandNames = {'Delta'; 'Theta'; 'Alpha'; 'Beta'};
numFreqBands = size(freqBands, 1);

%% Setup the recording map.
template = struct('uuid', NaN, 'site', NaN, 'study', NaN, 'labId', NaN, ...
    'srate', NaN, 'frequencies', NaN, 'scales', NaN, ...
    'correlations', NaN, 'bandCorrelations', NaN);

%% Initialize fingerprints and check channels are all there
spectrumPrint = [];
bandPrint = [];
[EEGNew, missing] = selectEEGChannels(EEG, channels);
if ~isempty(missing)
    warning('EEG is missing %d channels -- can not compute spectral fingerprints', ...
           length(missing);
       return;
end
numChannels = length(channels);

%% Compute the wavelet scales
T = 1/EEGNew.srate;
[tScales, tFreqs] = freq2scales(freqRange(1), freqRange(2), numFrequencies, wname, T);
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
    tfdecomp{c, m} = bsxfun(@times, tfd, 1./ baselineRobustStd);
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

