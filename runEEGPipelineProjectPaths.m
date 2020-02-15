%% Run this script to set the project paths

%%Get the path to this directory
scriptFile = mfilename('fullpath');
[scriptFolder, scriptName] = fileparts(scriptFile);
addpath(scriptFolder);

%% Add the path for utilities
thisPath = [scriptFolder filesep 'utilities'];
addpath(genpath(thisPath));

%% Add paths for the pipelines
thisPath = [scriptFolder filesep 'pipelines'];
addpath(genpath(thisPath));

%% Add paths for analysis scripts
thisPath = [scriptFolder filesep 'analysis'];
addpath(genpath(thisPath));

%% Eye catch paths
eyeCatchPath = 'D:\Research\EEGPipelineProject\eye-catch';
addpath(eyeCatchPath);
addpath(genpath([eyeCatchPath filesep 'document']));
addpath(genpath([eyeCatchPath filesep 'unit_test']));