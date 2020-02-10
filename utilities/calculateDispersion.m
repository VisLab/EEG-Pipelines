function dispersion = calculateDispersion(amplitudeMatrix)
%% Computes the disperson of an amplitude matrix
%
%  Parameters:
%      amplitudeMatrix = channels x recordings array of recording 
%                        channelAmplitude vectors
%      dispersion        channels x 1 vector with dispersion of amplitudeMatrix
%      

%% Calculate the dispersion
dispersion = stdFromMad(amplitudeMatrix) ./ median(amplitudeMatrix); 