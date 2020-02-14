function listString = getListString(listOfStrings)
%% Return a cell array of strings as a single string separated by comma

listString = listOfStrings{1};
for k = 2:length(listOfStrings)
    listString = [listString ',' listOfStrings{k}];
end
