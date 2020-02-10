function [EEG, isFrameAnArtifact] = insertICA(EEG, icaType)

isFrameAnArtifact = [];
if strcmpi(icaType, 'runica')
    [cleanEEG, isFrameAnArtifact]= cleanWindows(EEG);
    cleanEEG = runicaLowrank(cleanEEG, 'off');
    EEG.icawinv = cleanEEG.icawinv;
    EEG.icasphere = cleanEEG.icasphere;
    EEG.icaweights = cleanEEG.icaweights;
    EEG.icachansind = 1:EEG.nbchan;
elseif strcmpi(icaType, 'infomax')
    [cleanEEG, isFrameAnArtifact]= cleanWindows(EEG);
    cleanEEG = cudaica_lowrank(cleanEEG, 'off');
    EEG.icawinv = cleanEEG.icawinv;
    EEG.icasphere = cleanEEG.icasphere;
    EEG.icaweights = cleanEEG.icaweights;
    EEG.icachansind = 1:EEG.nbchan;
elseif isempty(EEG.icawinv)
    warning('insertICA: ICs were not computed nor did they previously exist')
end
