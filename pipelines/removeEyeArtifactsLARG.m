function [EEG, removalInfo] = removeEyeArtifactsLARG(EEG, blinkInfo, ...
                         icaType, regressBlinkEvents, regressBlinkSignal)
%% Remove eye artifacts from EEG using LARG pipeline
%
% Parameters:
%      EEG    (input/output) may have ICs added to EEG 
%      blinkInfo     Blink information structure from Blinker output.
%                    If empty, blink information is not used at all
%      icaType       Indicates whether ICs should be computed and/or used
%          runica        uses ordinary runica
%          infomax       uses cudaica (which must be installed)
%          xxx           anything else (not empty) assumes ICs computed coming in
%          ''            empty string indicates don't compute ICs or use eyecatch
%      regressBlinkEvents  if true, blink events are regressed out
%      regressBlinkSignal  if true, blink signal is regressed out
%
% Currently regressing out blink events and blink signal are not available.
% The current implementation just subtracts out the blink signal.

%% Run ICA if needed and perform eyeCatch to remove bad ICS
removalInfo = [];
if ~isempty(icaType)
    [EEG, isFrameAnArtifact] = insertICA(EEG, icaType);
    eyeDetector = eyeCatch;
    [isEye, ~, scalpmapObj] = eyeDetector.detectFromEEG(EEG);
    
    EEG.etc.eyeICs.icaNumbers = find(isEye);
    EEG.etc.eyeICs.icawinv = EEG.icawinv(:,isEye);
    EEG.etc.eyeICs.icaweights = EEG.icaweights(isEye,:);
    removalInfo = EEG.etc.eyeICs;
    
    if isempty(EEG.icachansind)
        EEG.icachansind = 1:size(EEG.data,1);
    end
    EEG = pop_subcomp(EEG, find(isEye));
    removalInfo.isFrameAnArtifact = isFrameAnArtifact;
    removalInfo.isEye = isEye;
    removalInfo.scalpmapObj = scalpmapObj;
    removalInfo.chanlocs = EEG.chanlocs;
end

%% Now regress out blink information if requested
if ~isempty(blinkInfo)
    if regressBlinkEvents
        warning('Regressing out blink events is currently not implemented for LARG');
        if regressBlinkSignal
             warning('Regressing out blink signal is currently not implemented for LARG');
        end
    elseif ~isempty(blinkInfo.blinkSignal)
        x = EEG.data / blinkInfo.blinkSignal;
        EEG.data = EEG.data - x * blinkInfo.blinkSignal;
    end
end
