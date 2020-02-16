function [blinkPowerRatios, nonBlinkPowerRatios, blinkAmpRatios,  ...
           nonBlinkAmpRatios, numBlinks, numOverlaps] = ...
                               getEEGBlinkRatios(EEG, inRange, outRange) 
       
%% Initialze the calculation
[numChans, numFrames] = size(EEG.data);
srate = EEG.srate;
events = EEG.event;
eventTypes = {EEG.event.type};
maxMask = strcmpi(eventTypes, 'maxFrame');
numBlinks = sum(maxMask);
blinkPowerRatios = nan(numChans, numBlinks);
blinkAmpRatios = nan(numChans, numBlinks);
blinkEvents = events(maxMask);

blinkFrames = round(cell2mat({blinkEvents.latency}));
minTime = min(min(inRange(:)), min(outRange(:)));
maxTime = max(max(inRange(:)), max(outRange(:)));
minFrames = round(minTime*srate);
maxFrames = round(maxTime*srate);
minInFrames = round(min(inRange(:))*srate);
maxInFrames = round(max(inRange(:))*srate);
tValues = (minFrames:maxFrames)/srate;
%% Now process the blinks one at a time
blinkMask = false(numFrames, 1);
data = EEG.data;
overlapMask = false(numBlinks, 1);
for b = 1:numBlinks
    signalFrames = (blinkFrames(b) + minFrames):(blinkFrames(b) + maxFrames);
    inRangeFrames = (blinkFrames(b) + minInFrames):(blinkFrames(b) + maxInFrames);
    inRangeFrames(inRangeFrames <= 0) = [];
    inRangeFrames(inRangeFrames > numFrames) = [];
    if sum(signalFrames <= 0) > 0 || sum(signalFrames > numFrames) > 0 ...
            || sum(blinkMask(inRangeFrames)) > 0
        overlapMask(b) = true;
     
    else
        signal = data(:, signalFrames);
        [blinkPowerRatios(:, b), blinkAmpRatios(:, b)] = ...
            getBlinkRatio(signal, tValues, inRange, outRange);
    end
   blinkMask(inRangeFrames) = true;
end
numOverlaps = sum(overlapMask);
%% Now remove overlapping blinks
blinkPowerRatios(:, overlapMask) = [];
blinkAmpRatios(:, overlapMask) = [];
numBlinks = size(blinkPowerRatios, 2);
nonBlinkPowerRatios = nan(numChans, numBlinks);
nonBlinkAmpRatios = nan(numChans, numBlinks);
%% Now compute ratios for non-blink sections
b = 0;
while (b < numBlinks)
    nonBlinkFrame = round(numFrames*rand(1, 1));
    signalFrames = (nonBlinkFrame + minFrames):(nonBlinkFrame + maxFrames);
    inRangeFrames = (nonBlinkFrame + minInFrames):(nonBlinkFrame + maxInFrames);
    inRangeFrames(inRangeFrames <= 0) = [];
    inRangeFrames(inRangeFrames > numFrames) = [];
    if sum(signalFrames <= 0) > 0 || sum(signalFrames > numFrames) > 0 ...
            || sum(blinkMask(inRangeFrames)) > 0
        continue;
    end
    b = b + 1;
    signal = data(:, signalFrames);
    [nonBlinkPowerRatios(:, b), nonBlinkAmpRatios(:, b)] = ...
        getBlinkRatio(signal, tValues, inRange, outRange);
end