function [EEG, removalInfo] = removeArtifactsMara(EEG, icaType)
%% Performs the MARA algorithm to remove artifacts.
%
%  Parameters:
%    EEG  (input/output) EEG may be modified with new ICS

%% Insert the ICAs if not already there
[EEG, isFrameAnArtifact] = insertICA(EEG, icaType);

if isempty(EEG.icaweights)
   error('removeArtifactsMara: EEG does not have ICs so MARA can not continue');
end

%% Perform the MARA algorithms to identify bad ICs
[artcomps, maraInfo] = MARARevised(EEG);

%% Remove bad ICs
rejectMask = zeros(1, size(EEG.icawinv, 2));
rejectMask(artcomps) = 1;
EEG.reject.gcompreject = rejectMask;
EEG.rejectMARAInfo = maraInfo;
if length(artcomps) == length(rejectMask)
    error('removeArtifactsMara: MARA detects all components as error');
end
EEG = pop_subcomp(EEG, artcomps);

%% Update the removalInfo
removalInfo = struct();
removalInfo.isFrameAnArtifact = isFrameAnArtifact;
removalInfo.artcmps = artcomps;
removalInfo.chanlocs = EEG.chanlocs;
removalInfo.maraInfo = maraInfo;