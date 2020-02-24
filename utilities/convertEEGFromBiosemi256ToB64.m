function [EEG, chanMap] = convertEEGFromBiosemi256ToB64(EEG, overwriteLocs)
%% Convert 256 channel Biosemi EEG to 64 channels using Biosemi 64 channel map
%
% Parameters:
%    EEG             (input/output) EEGLAB set file
%    chanMap         table of Biosemi 64 channels mapping to Biosemi 256 headset
%    
%% 
    %% Load the label correspondence and channel locations
    temp = load('B64Channels.mat');
    chanlocs64 = temp.B64Chanlocs;
    chanMap = mapBiosemi256ToBiosemi64();
    
    %% Set up the B256 channel map
    chanlocs256 = EEG.chanlocs;
    labelMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for k = 1:length(chanlocs256)
        labelMap(chanlocs256(k).labels) = k;
    end
    labelMap64 = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for k = 1:length(chanlocs64)
        labelMap64(chanlocs64(k).labels) = k;
    end

    %% Now map the channels
    chanMask = false(1, length(chanlocs256));
    for k = 1:size(chanMap, 1)
        if ~isKey(labelMap, chanMap{k, 2})
            continue;
        end
        p1 = labelMap(chanMap{k, 2});
        chanMask(p1) = true;
        if overwriteLocs
            p2 = labelMap64(chanMap{k, 1});
            chanlocs256(p1) = chanlocs64(p2);
        else
            chanlocs256(p1).labels = chanMap{k, 1};
        end
    end
    chanlocs256 = chanlocs256(chanMask);
    EEG.data = EEG.data(chanMask, :);
    EEG.nbchan = length(chanlocs256);
    EEG.chanlocs = chanlocs256;
end