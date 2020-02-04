%% Extract the blinks structure based on channel or EOG time series
% This script assumes that EEGLAB is in the path, that the datasets are
% in EEGLAB EEG structures. 
%
% To run for your own data you must have first generated a 
% blink file list which contains a list of files with the appropriate 
% subject and other metadata.  See examples in
% ./moreExamples/addingSubjectInfo.
% 
% The BLINKER pipeline produces a directory of blink files (one file per data
% file). Each file contains a blinks structure with the eligible signals
% and metadata information, a blinkFits structure with the fits for the
% used signal, a blinkProperties structure for the blinks of the used
% signal, a blinkStatistics structure with the statistics of the basic
% ocular indices, and the params structure used to run the program.
%
% See also pop_blinker 
%
% BLINKER extracts blinks and ocular indices from time series. 
% Copyright (C) 2016  Kay A. Robbins, Kelly Kleifgas, UTSA
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%% Setup
%pop_editoptions('option_single', false, 'option_savetwofiles', false);
params = struct();

%% NCTU_RWN_VDE
% study = 'NCTU_RWN_VDE';
% levelDerivedDir = 'D:\TestData\LargData\STDL2_128Hz\NCTU_RWN_VDE_STDL2_128Hz';
% infoDir = [levelDerivedDir filesep 'additional_data'];
% blinkDir = [infoDir filesep 'Blinks'];
% typeBlinks = 'Level2_128HzRef';
% blinkFileList = [infoDir filesep study '_blinkFileList.mat'];
% blinkIndDir = [blinkDir filesep typeBlinks];
% dataDir = [levelDerivedDir filesep 'session'];

%% Make the directory for the blink extraction
if ~exist(blinkDir, 'dir')
    mkdir(blinkDir);
end

if ~exist(blinkIndDir, 'dir')
    mkdir(blinkIndDir);
end

%% Load the file list
test = load(blinkFileList);
blinkFiles = test.blinkFiles;

%% Run the blinker blink extraction to create a file.
for k = 1:length(blinkFiles)
    fprintf('%d: %s\n', k, blinkFiles(k).fileName);
    blinkerSaveFile = [blinkIndDir filesep ...
                      blinkFiles(k).blinkFileName '_' typeBlinks '.mat'];
 
    try
        dataPath = [dataDir filesep blinkFiles(k).session];
        fileName = [dataPath filesep blinkFiles(k).level2_128HzName];
        EEG = pop_loadset(fileName);
        params = checkBlinkerDefaults(struct(), getBlinkerDefaults(EEG));
        params.subjectID = blinkFiles(k).subjectID;
        params.experiment = blinkFiles(k).experiment;
        params.uniqueName = blinkFiles(k).uniqueName;
        params.task = blinkFiles(k).task;
        params.fileName = fileName;
        params.startDate = blinkFiles(k).startDate;
        params.startTime = blinkFiles(k).startTime;
        params.signalNumbers = 1:62;
        params.blinkerSaveFile = blinkerSaveFile;
        params.dumpBlinkerStructures = true;
        params.blinkerDumpDir = blinkIndDir;
        params.dumpBlinkImages = false;
        params.dumpBlinkPositions = false;
        params.keepSignals = true;      % Make true if combining downstream
        params.showMaxDistribution = true;
        params.verbose = false;
        params.excludeLabels = {'a1', 'a2', 'EKG'}; 
       [EEG, com, blinks, blinkFits, blinkProperties, blinkStatistics, ...
           params] = pop_blinker(EEG, params); 
       close all;
    catch Mex
        blinks.status = ['failure:' Mex.message];
    end
end