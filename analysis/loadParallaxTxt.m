function [parallax, subs, glasses] = loadParallaxTxt(filename, distances)
% Load parallax cell array saved by saveParallaxTxt.
% Returns subs and glasses from the file; distances is supplied by caller.

    D = readtable(filename, ...
        'Delimiter', '\t', ...
        'FileType', 'text');

    subs = unique(string(D.subject), 'stable');
    glasses = unique(string(D.glasses), 'stable');

    parallax = cell(numel(subs), numel(glasses), numel(distances));

    for s = 1:numel(subs)
        for g = 1:numel(glasses)
            for d = 1:numel(distances)

                idx = string(D.subject) == subs(s) & ...
                      string(D.glasses) == glasses(g) & ...
                      string(D.distance) == string(distances(d));

                T = D(idx, {'target','median_acc_x','median_acc_y'});
                T = sortrows(T, 'target');

                parallax{s,g,d} = T;
            end
        end
    end

    subs = cellstr(subs);
    glasses = cellstr(glasses);
end
