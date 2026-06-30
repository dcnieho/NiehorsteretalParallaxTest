function componentTests = runComponentTests(subjectRows, glassesStr)

    varsToTest = [ ...
        "tx", ...
        "ty", ...
        "divergence", ...
        "anisotropic_scaling", ...
        "rotation_like", ...
        "shear_like"];

    componentTests = table();

    for r = 1:numel(glassesStr)

        trackerName = glassesStr(r);
        idx = subjectRows.tracker == trackerName;
        T = subjectRows(idx, :);

        for v = 1:numel(varsToTest)

            varName = varsToTest(v);
            x = T.(varName);
            x = x(~isnan(x));

            if numel(x) < 3
                continue
            end

            [~, p, ci, stats] = ttest(x, 0);

            newRow = table();

            newRow.tracker = trackerName;
            newRow.variable = varName;
            newRow.n = numel(x);
            newRow.mean = mean(x, 'omitnan');
            newRow.sd = std(x, 'omitnan');
            newRow.sem = newRow.sd ./ sqrt(newRow.n);
            newRow.t = stats.tstat;
            newRow.df = stats.df;
            newRow.p = p;
            newRow.ci_low = ci(1);
            newRow.ci_high = ci(2);

            componentTests = [componentTests; newRow]; %#ok<AGROW>
        end
    end

    % Benjamini-Hochberg FDR correction across all component-wise tests
    componentTests.p_fdr = fdrBH(componentTests.p);
end
