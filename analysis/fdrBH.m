function pAdj = fdrBH(p)
% Benjamini-Hochberg FDR correction.

    p = p(:);
    n = numel(p);

    [pSorted, sortIdx] = sort(p);
    ranks = (1:n)';

    qSorted = pSorted .* n ./ ranks;

    % Ensure monotonicity
    qSorted = flipud(cummin(flipud(qSorted)));

    qSorted(qSorted > 1) = 1;

    pAdj = nan(size(p));
    pAdj(sortIdx) = qSorted;
end
