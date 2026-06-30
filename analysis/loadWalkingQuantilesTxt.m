function [walkQuant, subs, glasses] = loadWalkingQuantilesTxt(filename)
% Load walking quantile plotting points saved by saveWalkingQuantilesTxt.

    walkQuant = readtable(filename, ...
        'Delimiter', '\t', ...
        'FileType', 'text');

    subs = cellstr(unique(string(walkQuant.subject), 'stable'));
    glasses = cellstr(unique(string(walkQuant.glasses), 'stable'));
end
