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
        obj = TemporalOverlapDesignOfEEG;
        obj = obj.createFromEEGStructure(EEG, 'eventCodes' , {'leftBase'    'leftZero'    'leftZeroHalfHeight'    'maxFrame'    'rightBase'    'rightZero'    'rightZeroHalfHeight'}...
            ,'addConstantScalar', true, 'useAllFrames', true, 'includeRampFactor', false, 'timeRange', [-1 1]);
        
        if regressBlinkSignal
            blinkSignalFactor = TemporalRegressionFactor;
            blinkSignalFactor.designMatrix = sparse(blinkInfo.blinkSignal(:));
            blinkSignalFactor.label = 'blink signal';
            
            obj = obj.addFactor(blinkSignalFactor, true);
        end
        [obj, lowlevelResults] = obj.computeFactorValues(EEG.data', 'significance', false, 'outlierMask', []);
        predictedData = obj.designMatrix * lowlevelResults.factorCoefficients;
        EEG.data = EEG.data - predictedData';
    elseif ~isempty(blinkInfo.blinkSignal)
        x = EEG.data / blinkInfo.blinkSignal;
        EEG.data = EEG.data - x * blinkInfo.blinkSignal;
    end
end
