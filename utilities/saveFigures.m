function errorMsgs = saveFigures(hFig, fileName, formats, closeFlag)
%% Save hFig in the specified formats
%
%  Parameters:
%      hFig      figure handle of the figure to be saved
%      fileName  full path of the file (without extension) for saving
%      formats   n x 2 cell array first column has the file extension and
%                the second column has the matlab format specification
%      closeFlag if true close the figure after saving the file
%
%  Example format specification:
%  formats = {'.png', 'png'; '.fig', 'fig'; '.pdf' 'pdf'; '.eps', 'epsc'};
%
%% Check the arguments
if nargin < 4
    closeFlag = [];
end
if isempty(formats)
    warning('%s: not saved because figure format list is empty', fileName);
    return
else
    errorMsgs = {};
    for m = 1:size(formats, 1)
        try
            saveas(hFig, [fileName formats{m, 1}], formats{m, 2});
        catch Mex
            errorMsgs{end + 1} = [fileName formats{m, 1} ':' Mex.message]; %#ok<*AGROW>
            warning(errorMsgs{end});
        end
    end
end

%% Now handle the closing of the figures
if ~isempty(closeFlag) && closeFlag
    try
        close(hFig);
    catch
        errorMsgs{end + 1} = [fileName formats{m, 1} ':' Mex.message];
        warning(errorMsgs{end});
    end
end