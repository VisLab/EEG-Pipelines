function [powerRatio, amplitudeRatio] = getBlinkRatios(signal, tValues, inRange, outRange)   
%% Return the ratios of power and amplitude within the blink to outside blink
%
%  Parameters:
%      signal           m x 1 vector with signal containing blink (signal or ERP)
%      tValues          m x 1 vector with corresponding time values
%      inRange          n x 2 array of start and end times of intervals within blink
%      outRange         n x 2 array of start and end times of intervals outside blink
%      powerRatio       (output) positive value of out/in power
%      amplitudeRatio   (output) postivie value of out/in amplitude

%%  Calculate the inMask and outMask
inMask = false(length(signal), 1);
for k = 1:size(inRange, 1)
    inMask = inMask | (inRange(k, 1) <= tValues & tValues <= inRange(k, 2));
end

outMask = false(length(signal), 1);
for k = 1:size(outRange, 1)
    outMask = outMask | (outRange(k, 1) <= tValues & tValues <= outRange(k, 2));
end

%% Calculate the ratios
outSignal = signal(outMask);
inSignal = signal(inMask);

outMean = mean(outSignal);
outSignal = bsxfun(@minus, outSignal, outMean);
inSignal = bsxfun(@minus, inSignal, outMean);

powerRatio = mean(inSignal.*inSignal)/mean(outSignal.*outSignal);
amplitudeRatio = mean(abs(inSignal))/mean(abs(outSignal));
