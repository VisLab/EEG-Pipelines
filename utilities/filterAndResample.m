function EEG = filterAndResample(EEG, highPassFrequency, maxSamplingRate)
% Removes channel mean, filters, resamples, and removes extra fields from EEG.etc.noiseDetection 
%
%  Parameters:
%      EEG    (input/output) EEG to be filtered (only has EEG channels)
%      highPassFrequency   high pass filter at this frequency if non empty
%      maxSamplingRate     resample if non-empty and lower than EEG.srate
%      
%% Remove channel mean  
EEG.data = bsxfun(@minus, EEG.data, mean(EEG.data, 2));

%% High pass filter
if ~isempty(highPassFrequency)
    EEG = pop_eegfiltnew(EEG, highPassFrequency, [], [], [], [], 0);
end
%% Resample if necessary
if ~isempty(maxSamplingRate) && EEG.srate > maxSamplingRate
    EEG = pop_resample(EEG, maxSamplingRate);
end

EEG.etc.filterAndResample.maxSamplingRate = maxSamplingRate;
EEG.etc.filterAndResample.filterType = 'highpass';
EEG.etc.filterAndResample.highPassFrequency = highPassFrequency;

%% Clean up the reference metadata as appropriate
if isfield(EEG.etc, 'noiseDetection') && ...
        isfield(EEG.etc.noiseDetection, 'reference')
    EEG.etc.noiseDetection.reference = ...
        cleanupReference(EEG.etc.noiseDetection.reference);
end
    
