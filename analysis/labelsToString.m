function labels = labelsToString(x, n, prefix)

    if nargin < 3
        prefix = "Item";
    end

    if isempty(x)
        labels = strings(n,1);
        for i = 1:n
            labels(i) = prefix + string(i);
        end
        return
    end

    if isstring(x)
        labels = x(:);
    elseif iscellstr(x)
        labels = string(x(:));
    elseif ischar(x)
        labels = string(cellstr(x));
    elseif isnumeric(x)
        labels = string(x(:));
    elseif iscell(x)
        labels = string(x(:));
    else
        labels = string(x(:));
    end

    if numel(labels) ~= n
        labels = strings(n,1);
        for i = 1:n
            labels(i) = prefix + string(i);
        end
    end
end
