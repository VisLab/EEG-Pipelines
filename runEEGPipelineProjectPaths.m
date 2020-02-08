%% Run this script to set the project paths

%%Get the path to this directory
scriptFile = mfilename('fullpath');
[scriptFolder, scriptName] = fileparts(scriptFile);
addpath(scriptFolder);
thisPath = [scriptFolder filesep 'utilities'];
addpath(genpath(thisPath));

%% Add paths for ASR
thisPath = [scriptFolder filesep 'ASR'];
addpath(genpath(thisPath));

%% Add paths for ASRalt
thisPath = [scriptFolder filesep 'ASRalt'];
addpath(genpath(thisPath));

%% Add paths for LARG
thisPath = [scriptFolder filesep 'LARG'];
addpath(genpath(thisPath));

%% Add paths for MARA
thisPath = [scriptFolder filesep 'MARA'];
addpath(genpath(thisPath));

%% Add paths to utilities
thisPath = [scriptFolder filesep 'utilities'];
addpath(genpath(thisPath));

%% Add paths for eye-catch
eyeCatchPath = 'D:\Research\EEGPipelineProject\eye-catch';
addpath(eyeCatchPath);
addpath(genpath([thisPath filesep 'document']));
addpath(genpath([thisPath filesep 'unit_test']));
