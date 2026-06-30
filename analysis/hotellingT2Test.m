function out = hotellingT2Test(X)
% One-sample Hotelling T^2 test against a zero vector.
%
% Rows are subjects.
% Columns are variables.

    X = X(all(~isnan(X), 2), :);

    [n, p] = size(X);

    out = struct();
    out.n = n;
    out.p = p;
    out.T2 = NaN;
    out.F = NaN;
    out.df1 = p;
    out.df2 = n - p;
    out.p = NaN;

    if n <= p
        warning('Hotelling T2 requires n > p. Got n = %d, p = %d.', n, p);
        return
    end

    mu = mean(X, 1)';
    S = cov(X);

    % Use pseudo-inverse for numerical stability
    T2 = n * mu' * pinv(S) * mu;

    F = ((n - p) / (p * (n - 1))) * T2;

    df1 = p;
    df2 = n - p;

    pval = 1 - fcdf(F, df1, df2);

    out.T2 = T2;
    out.F = F;
    out.df1 = df1;
    out.df2 = df2;
    out.p = pval;
end
