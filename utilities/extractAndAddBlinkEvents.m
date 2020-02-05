function [EEG, blinkInfo] = extractAndAddBlinkEvents(EEG)

% close pop_blinker() figure without affecting others.
allFigureHandles = get(0,'children');
allFigureHandleVisibilities = get(allFigureHandles, 'handlevisibility');
set(allFigureHandles, 'handlevisibility', 'off');
try
    [~, ~, blinkInfo.blinks, blinkInfo.blinkFits, blinkInfo.blinkProperties, ...
        blinkInfo.blinkStatistics, params] = pop_blinker(EEG, struct());
    if exist(params.blinkerSaveFile, 'file')
        delete(params.blinkerSaveFile);
    end
catch
    blinkInfo = [];
    return;
end
close all;
try
    set(allFigureHandles, 'handlevisibility', allFigureHandleVisibilities);
catch
end

[EEG, blinkInfo.blinkSignal] = addBlinkEvents(EEG, blinkInfo.blinks, ...
     blinkInfo.blinkFits, blinkInfo.blinkProperties, {'maxFrame', 'leftZero', 'rightZero', 'leftBase', 'rightBase', 'leftZeroHalfHeight', 'rightZeroHalfHeight'});
EEG = eeg_checkset(EEG);