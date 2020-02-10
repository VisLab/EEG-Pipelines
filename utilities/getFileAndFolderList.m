function fileList = getFileAndFolderList(fileOrFolderList, searchQuery, recursive)
%% Return a list of files and folders meeting specified search query
%
%  Parameters:
%     fileOrFolderList    cell array or string containing a list of files and/or folders
%     searchQuery         cell array of wildcards, default: {'*.mat' '*.sto'}
%     recursive           if true, searches subdirectories recursively
%     fileList            (output) cell array of full paths of files meeting requirements
%
%% Check the parameters
if nargin < 2
    searchQuery = {'*.mat' '*.sto'};
end

if ischar(searchQuery)
    searchQuery = {searchQuery};
end

if nargin < 3
    recursive = false;
end

if ischar(fileOrFolderList)
    fileOrFolderList = {fileOrFolderList};
end

%% Traverse the directories creating the full path list of files and folders
fileList = {};
counter = 1;
for i=1:length(fileOrFolderList)
    if exist(fileOrFolderList{i}, 'dir')
        d = dir([fileOrFolderList{i} filesep searchQuery{1}]);
        for j = 2:length(searchQuery)
            if isempty(d)
                d = dir([fileOrFolderList{i} filesep searchQuery{j}]);
            else
                d = [vec(d); vec(dir([fileOrFolderList{i} filesep searchQuery{j}]))];
            end
        end
        
        fileList = [fileList strcat([fileOrFolderList{i} filesep], {d.name})];         %#ok<*AGROW>
        
        if recursive
            subfolders = dir(fileOrFolderList{i});
            subfolderFileList = {}; %#ok<NASGU>
            for j=1:length(subfolders)
                if subfolders(j).isdir && ~(strcmp(subfolders(j).name, '.') || strcmp(subfolders(j).name, '..'))
                    subfolderFileList = getFileAndFolderList([fileOrFolderList{i} filesep subfolders(j).name], searchQuery, true);
                    fileList = [fileList subfolderFileList];
                end
            end
        end
        
        counter = length(fileList) + 1;
        
    elseif exist(fileOrFolderList{i}, 'file')
        fileList{counter} = fileOrFolderList{i};
        counter = counter + 1;
    end
end
